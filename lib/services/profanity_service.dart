import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:uuid/uuid.dart';

/// Service for detecting profanity in transcripts
class ProfanityService {
  final Map<String, Set<String>> _wordLists = {};
  final Set<String> _customWords = {};
  final Set<String> _excludedWords = {};
  final _uuid = const Uuid();

  /// Initialize word lists for a language
  Future<void> loadWordList(String language) async {
    // TODO: Load from assets/wordlists/{language}.txt
    // For now, use a default English list
    _wordLists[language] = _defaultEnglishWords;
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
        confidence: 1.0,
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
          confidence: 1.0,
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

  String _normalize(String word) {
    return word
        .toLowerCase()
        .replaceAll(RegExp(r"[^\w\s']"), '')
        .trim();
  }

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
    // TODO: Implement Double Metaphone encoding
    // For now, use simple fuzzy matching for common misspellings
    for (final entry in _wordLists.entries) {
      for (final badWord in entry.value) {
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

  // Default English profanity list (minimal for testing)
  static final Set<String> _defaultEnglishWords = {
    // Add actual profanity words in production
    'placeholder',
  };
}

class _PhoneticMatchResult {
  final String matchedWord;
  final double confidence;

  _PhoneticMatchResult({required this.matchedWord, required this.confidence});
}
