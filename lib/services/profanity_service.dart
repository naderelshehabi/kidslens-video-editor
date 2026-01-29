import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:uuid/uuid.dart';

/// Language metadata for profanity detection
class LanguageInfo {

  const LanguageInfo({
    required this.code,
    required this.name,
    required this.rtl,
  });

  factory LanguageInfo.fromJson(Map<String, dynamic> json) => LanguageInfo(
      code: json['code'] as String,
      name: json['name'] as String,
      rtl: json['rtl'] as bool,
    );
  final String code;
  final String name;
  final bool rtl;
}

/// Service for detecting profanity in transcripts
class ProfanityService {
  final Map<String, Set<String>> _wordLists = {};
  final Map<String, String> _phoneticCache = {};
  final Set<String> _customWords = {};
  final Set<String> _excludedWords = {};
  final _uuid = const Uuid();

  List<LanguageInfo> _languages = [];
  bool _metadataLoaded = false;

  /// Get list of supported languages
  List<LanguageInfo> get supportedLanguages => List.unmodifiable(_languages);

  /// Check if a language is loaded
  bool isLanguageLoaded(String languageCode) =>
      _wordLists.containsKey(languageCode);

  /// Load language metadata from assets
  Future<void> loadMetadata() async {
    if (_metadataLoaded) return;

    try {
      final jsonString =
          await rootBundle.loadString('assets/wordlists/metadata.json');
      final data = json.decode(jsonString) as Map<String, dynamic>;
      final languagesList = data['languages'] as List<dynamic>;
      _languages = languagesList
          .map((e) => LanguageInfo.fromJson(e as Map<String, dynamic>))
          .toList();
      _metadataLoaded = true;
    } catch (e) {
      // Fallback to default English if metadata fails to load
      _languages = [
        const LanguageInfo(code: 'en', name: 'English', rtl: false),
      ];
      _metadataLoaded = true;
    }
  }

  /// Load wordlist for a specific language from assets
  Future<void> loadWordlist(String languageCode) async {
    if (_wordLists.containsKey(languageCode)) return;

    try {
      final content =
          await rootBundle.loadString('assets/wordlists/$languageCode.txt');
      final words = _parseWordlist(content);
      _wordLists[languageCode] = words;

      // Pre-compute phonetic encodings for the wordlist
      for (final word in words) {
        _phoneticCache[word] = _doubleMetaphoneEncode(word);
      }
    } catch (e) {
      // If wordlist doesn't exist, create an empty set
      _wordLists[languageCode] = {};
    }
  }

  /// Parse wordlist content, filtering comments and empty lines
  Set<String> _parseWordlist(String content) {
    final lines = content.split('\n');
    final words = <String>{};

    for (final line in lines) {
      final trimmed = line.trim();
      // Skip comments and empty lines
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      words.add(trimmed.toLowerCase());
    }

    return words;
  }

  /// Initialize word lists for a language (legacy method for compatibility)
  Future<void> loadWordList(String language) async {
    await loadMetadata();
    await loadWordlist(language);
  }

  /// Add custom bad words
  void addCustomWords(List<String> words) {
    _customWords.addAll(words.map((w) => w.toLowerCase()));
  }

  /// Add words to exclude from detection
  void excludeWords(List<String> words) {
    _excludedWords.addAll(words.map((w) => w.toLowerCase()));
  }

  /// Detect profanity in a transcript
  List<ProfanityMatch> detect(Transcript transcript) {
    final matches = <ProfanityMatch>[];

    for (final segment in transcript.segments) {
      for (final transcriptWord in segment.words) {
        final match = _matchWord(transcriptWord);
        if (match != null) {
          matches.add(match);
        }
      }
    }

    return matches;
  }

  ProfanityMatch? _matchWord(TranscriptWord transcriptWord) {
    final normalized = _normalize(transcriptWord.word);

    // Check exclusion list first
    if (_excludedWords.contains(normalized)) {
      return null;
    }

    // Check custom words (highest priority)
    if (_customWords.contains(normalized)) {
      return ProfanityMatch(
        id: _uuid.v4(),
        word: transcriptWord,
        matchedProfanity: normalized,
        confidence: 1,
        type: MatchType.exact,
      );
    }

    // Check against loaded word lists
    for (final entry in _wordLists.entries) {
      if (entry.value.contains(normalized)) {
        return ProfanityMatch(
          id: _uuid.v4(),
          word: transcriptWord,
          matchedProfanity: normalized,
          confidence: 1,
          type: MatchType.exact,
        );
      }
    }

    // Check leetspeak normalization
    final leetspeakNormalized = _normalizeLeetspeak(normalized);
    if (leetspeakNormalized != normalized) {
      for (final entry in _wordLists.entries) {
        if (entry.value.contains(leetspeakNormalized)) {
          return ProfanityMatch(
            id: _uuid.v4(),
            word: transcriptWord,
            matchedProfanity: leetspeakNormalized,
            confidence: 0.9,
            type: MatchType.leetspeak,
          );
        }
      }
    }

    // Check phonetic matching
    final phoneticMatch = _findPhoneticMatch(normalized);
    if (phoneticMatch != null) {
      return ProfanityMatch(
        id: _uuid.v4(),
        word: transcriptWord,
        matchedProfanity: phoneticMatch.matchedWord,
        confidence: phoneticMatch.confidence,
        type: MatchType.phonetic,
      );
    }

    return null;
  }

  String _normalize(String word) =>
      word.toLowerCase().replaceAll(RegExp(r"[^\w\s']"), '').trim();

  String _normalizeLeetspeak(String word) {
    const leetspeakMap = {
      '0': 'o',
      '1': 'i',
      '3': 'e',
      '4': 'a',
      '5': 's',
      '7': 't',
      '@': 'a',
      '\$': 's',
    };

    var result = word;
    for (final entry in leetspeakMap.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  _PhoneticMatchResult? _findPhoneticMatch(String word) {
    // Use Double Metaphone encoding for phonetic matching
    final wordPhonetic = _doubleMetaphoneEncode(word);
    if (wordPhonetic.isEmpty) return null;

    for (final entry in _wordLists.entries) {
      for (final badWord in entry.value) {
        // Check cached phonetic encoding
        final badWordPhonetic =
            _phoneticCache[badWord] ?? _doubleMetaphoneEncode(badWord);

        if (badWordPhonetic.isNotEmpty && wordPhonetic == badWordPhonetic) {
          return _PhoneticMatchResult(
            matchedWord: badWord,
            confidence: 0.85,
          );
        }

        // Also check similarity for partial matches
        if (_isSimilar(word, badWord)) {
          return _PhoneticMatchResult(
            matchedWord: badWord,
            confidence: 0.8,
          );
        }
      }
    }
    return null;
  }

  /// Double Metaphone encoding algorithm
  /// Produces a phonetic encoding of words for fuzzy matching
  String _doubleMetaphoneEncode(String input) {
    if (input.isEmpty) return '';

    final word = input.toUpperCase().replaceAll(RegExp('[^A-Z]'), '');
    if (word.isEmpty) return '';

    final result = StringBuffer();
    var current = 0;

    // Skip initial silent letters
    if (_startsWithSilent(word)) {
      current = 1;
    }

    while (current < word.length && result.length < 4) {
      final char = word[current];

      switch (char) {
        case 'A':
        case 'E':
        case 'I':
        case 'O':
        case 'U':
          // Only encode vowels at start
          if (current == 0) result.write('A');
          current++;

        case 'B':
          result.write('P');
          current +=
              (current + 1 < word.length && word[current + 1] == 'B') ? 2 : 1;

        case 'C':
          if (_isCHSound(word, current)) {
            result.write('X');
            current += 2;
          } else if (_isSoftC(word, current)) {
            result.write('S');
            current++;
          } else {
            result.write('K');
            current++;
          }

        case 'D':
          if (current + 1 < word.length && word[current + 1] == 'G') {
            if (_isSoftG(word, current + 1)) {
              result.write('J');
              current += 2;
            } else {
              result.write('TK');
              current += 2;
            }
          } else {
            result.write('T');
            current++;
          }

        case 'F':
          result.write('F');
          current +=
              (current + 1 < word.length && word[current + 1] == 'F') ? 2 : 1;

        case 'G':
          if (_isSoftG(word, current)) {
            result.write('J');
          } else {
            result.write('K');
          }
          current++;

        case 'H':
          // H is silent unless between vowels or at start before vowel
          if (_isVowel(word, current + 1) &&
              (current == 0 || !_isVowel(word, current - 1))) {
            result.write('H');
          }
          current++;

        case 'J':
          result.write('J');
          current++;

        case 'K':
          result.write('K');
          current +=
              (current + 1 < word.length && word[current + 1] == 'K') ? 2 : 1;

        case 'L':
          result.write('L');
          current +=
              (current + 1 < word.length && word[current + 1] == 'L') ? 2 : 1;

        case 'M':
          result.write('M');
          current +=
              (current + 1 < word.length && word[current + 1] == 'M') ? 2 : 1;

        case 'N':
          result.write('N');
          current +=
              (current + 1 < word.length && word[current + 1] == 'N') ? 2 : 1;

        case 'P':
          if (current + 1 < word.length && word[current + 1] == 'H') {
            result.write('F');
            current += 2;
          } else {
            result.write('P');
            current++;
          }

        case 'Q':
          result.write('K');
          current++;

        case 'R':
          result.write('R');
          current++;

        case 'S':
          if (current + 1 < word.length && word[current + 1] == 'H') {
            result.write('X');
            current += 2;
          } else {
            result.write('S');
            current++;
          }

        case 'T':
          if (current + 1 < word.length && word[current + 1] == 'H') {
            result.write('0'); // TH sound
            current += 2;
          } else if (current + 2 < word.length &&
              word.substring(current, current + 3) == 'TCH') {
            result.write('X');
            current += 3;
          } else {
            result.write('T');
            current++;
          }

        case 'V':
          result.write('F');
          current++;

        case 'W':
          if (_isVowel(word, current + 1)) {
            result.write('W');
          }
          current++;

        case 'X':
          result.write('KS');
          current++;

        case 'Y':
          if (_isVowel(word, current + 1)) {
            result.write('Y');
          }
          current++;

        case 'Z':
          result.write('S');
          current++;

        default:
          current++;
      }
    }

    return result.toString();
  }

  bool _startsWithSilent(String word) {
    const silentStarts = ['GN', 'KN', 'PN', 'WR', 'PS'];
    for (final silent in silentStarts) {
      if (word.startsWith(silent)) return true;
    }
    return false;
  }

  bool _isVowel(String word, int index) {
    if (index < 0 || index >= word.length) return false;
    return 'AEIOU'.contains(word[index]);
  }

  bool _isCHSound(String word, int index) {
    if (index + 1 >= word.length) return false;
    return word[index + 1] == 'H';
  }

  bool _isSoftC(String word, int index) {
    if (index + 1 >= word.length) return false;
    return 'EIY'.contains(word[index + 1]);
  }

  bool _isSoftG(String word, int index) {
    if (index + 1 >= word.length) return false;
    return 'EIY'.contains(word[index + 1]);
  }

  bool _isSimilar(String word1, String word2) {
    if ((word1.length - word2.length).abs() > 2) return false;

    // Simple Levenshtein distance check
    final distance = _levenshteinDistance(word1, word2);
    final maxLen = word1.length > word2.length ? word1.length : word2.length;
    return distance <= (maxLen * 0.3).ceil() && distance > 0;
  }

  int _levenshteinDistance(String s1, String s2) {
    final m = s1.length;
    final n = s2.length;
    final d = List.generate(m + 1, (_) => List.filled(n + 1, 0));

    for (var i = 0; i <= m; i++) {
      d[i][0] = i;
    }
    for (var j = 0; j <= n; j++) {
      d[0][j] = j;
    }

    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        d[i][j] = [
          d[i - 1][j] + 1,
          d[i][j - 1] + 1,
          d[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return d[m][n];
  }

  /// Clear all loaded wordlists
  void clearWordlists() {
    _wordLists.clear();
    _phoneticCache.clear();
  }

  /// Get loaded language codes
  Set<String> get loadedLanguages => _wordLists.keys.toSet();

  /// Get word count for a language
  int getWordCount(String languageCode) =>
      _wordLists[languageCode]?.length ?? 0;
}

class _PhoneticMatchResult {
  _PhoneticMatchResult({required this.matchedWord, required this.confidence});

  final String matchedWord;
  final double confidence;
}
