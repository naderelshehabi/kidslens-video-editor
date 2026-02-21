import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// BPE tokenizer for CLIP ViT-B/32 text encoder.
///
/// CLIP uses a byte-pair encoding (BPE) tokenizer with a vocabulary of 49,408
/// tokens. The tokenizer processes text into token IDs padded/truncated to
/// exactly 77 tokens, suitable for the CLIP text encoder's input shape [1, 77].
///
/// For built-in categories, pre-tokenized constants are provided to avoid
/// needing the vocabulary file at runtime.
class ClipTokenizer {
  ClipTokenizer._({
    required Map<String, int> encoder,
    required List<_BpePair> bpeRanks,
  })  : _encoder = encoder,
        _bpeRanks = bpeRanks;

  final Map<String, int> _encoder;
  final List<_BpePair> _bpeRanks;

  // Cache for BPE results
  final Map<String, List<String>> _bpeCache = {};

  /// Start-of-text token
  static const int sotToken = 49406;

  /// End-of-text token
  static const int eotToken = 49407;

  /// Maximum context length (padded/truncated to this)
  static const int contextLength = 77;

  /// Regex pattern for tokenization (matches CLIP's original pattern)
  static final RegExp _pat = RegExp(
    r"""<\|startoftext\|>|<\|endoftext\|>|'s|'t|'re|'ve|'m|'ll|'d|[\p{L}]+|[\p{N}]|[^\s\p{L}\p{N}]+""",
    unicode: true,
    caseSensitive: false,
  );

  /// Load tokenizer from a BPE vocabulary file.
  ///
  /// The vocab file is the standard `bpe_simple_vocab_16e6.txt` used by
  /// OpenAI's CLIP (48,643 merge pairs).
  static Future<ClipTokenizer> load(String vocabPath) async {
    final file = File(vocabPath);
    final List<String> lines;

    if (vocabPath.endsWith('.gz')) {
      final compressed = await file.readAsBytes();
      final decompressed = gzip.decode(compressed);
      lines = utf8.decode(decompressed).split('\n');
    } else {
      lines = await file.readAsLines();
    }

    // Build byte encoder (maps bytes 0-255 to unicode characters)
    final byteEncoder = _bytesToUnicode();

    // Build BPE ranks from merge lines
    // Skip first line (header) and last empty line
    final merges = <_BpePair>[];
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final parts = line.split(' ');
      if (parts.length == 2) {
        merges.add(_BpePair(parts[0], parts[1]));
      }
    }

    // Build encoder vocabulary
    // First 256 entries are byte tokens, next 256 are byte tokens + </w>
    final encoder = <String, int>{};
    final byteValues = byteEncoder.values.toList();

    for (var i = 0; i < byteValues.length; i++) {
      encoder[byteValues[i]] = i;
    }
    for (var i = 0; i < byteValues.length; i++) {
      encoder['${byteValues[i]}</w>'] = byteValues.length + i;
    }

    // Add merged tokens
    for (var i = 0; i < merges.length; i++) {
      final merged = '${merges[i].a}${merges[i].b}';
      encoder[merged] = 512 + i;
    }

    // Add special tokens
    encoder['<|startoftext|>'] = sotToken;
    encoder['<|endoftext|>'] = eotToken;

    return ClipTokenizer._(encoder: encoder, bpeRanks: merges);
  }

  /// Tokenize a text string into token IDs, padded to [contextLength].
  ///
  /// Returns an Int32 list of exactly [contextLength] elements suitable for
  /// the CLIP text encoder input shape [1, 77].
  Int32List tokenize(String text) {
    final tokens = <int>[sotToken];

    final cleanedText = _whitespaceClean(text.toLowerCase());

    for (final match in _pat.allMatches(cleanedText)) {
      final word = match.group(0)!;
      // Encode each byte of the word using the byte encoder
      final encoded = _encodeWord(word);
      final bpeTokens = _bpe(encoded);

      for (final token in bpeTokens) {
        final id = _encoder[token];
        if (id != null) {
          tokens.add(id);
        }
      }
    }

    tokens.add(eotToken);

    // Pad or truncate to contextLength
    final result = Int32List(contextLength);
    final copyLen = tokens.length < contextLength ? tokens.length : contextLength;

    // If truncating, ensure EOT is at the end
    for (var i = 0; i < copyLen; i++) {
      result[i] = tokens[i];
    }
    if (tokens.length > contextLength) {
      result[contextLength - 1] = eotToken;
    }

    return result;
  }

  /// Encode a word's bytes using the byte-to-unicode mapping.
  String _encodeWord(String word) {
    final byteEncoder = _bytesToUnicode();
    final bytes = utf8.encode(word);
    final buffer = StringBuffer();
    for (final b in bytes) {
      buffer.write(byteEncoder[b] ?? '');
    }
    return buffer.toString();
  }

  /// Apply BPE merges to a word, returning list of BPE tokens.
  List<String> _bpe(String token) {
    if (_bpeCache.containsKey(token)) {
      return _bpeCache[token]!;
    }

    // Split into individual characters, adding </w> to the last one
    var word = <String>[];
    for (var i = 0; i < token.length - 1; i++) {
      word.add(token[i]);
    }
    if (token.isNotEmpty) {
      word.add('${token[token.length - 1]}</w>');
    }

    if (word.length == 1) {
      _bpeCache[token] = word;
      return word;
    }

    while (true) {
      // Find the pair with the lowest rank
      int? minRank;
      int minIdx = -1;

      for (var i = 0; i < word.length - 1; i++) {
        final rank = _getRank(word[i], word[i + 1]);
        if (rank != null && (minRank == null || rank < minRank)) {
          minRank = rank;
          minIdx = i;
        }
      }

      if (minRank == null) break;

      // Merge the pair
      final newWord = <String>[];
      var i = 0;
      while (i < word.length) {
        if (i == minIdx && i < word.length - 1) {
          newWord.add('${word[i]}${word[i + 1]}');
          i += 2;
        } else {
          newWord.add(word[i]);
          i++;
        }
      }
      word = newWord;

      if (word.length == 1) break;
    }

    _bpeCache[token] = word;
    return word;
  }

  /// Get the rank of a BPE pair, or null if not found.
  int? _getRank(String a, String b) {
    for (var i = 0; i < _bpeRanks.length; i++) {
      if (_bpeRanks[i].a == a && _bpeRanks[i].b == b) {
        return i;
      }
    }
    return null;
  }

  /// Clean whitespace in text.
  static String _whitespaceClean(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Build byte-to-unicode mapping (standard CLIP BPE byte encoding).
  ///
  /// Maps bytes 0-255 to printable unicode characters, avoiding control
  /// characters and whitespace that would interfere with BPE processing.
  static Map<int, String> _bytesToUnicode() {
    // Printable ASCII + Latin-1 Supplement ranges
    final bs = <int>[];
    bs.addAll(List.generate('~'.codeUnitAt(0) - '!'.codeUnitAt(0) + 1,
        (i) => '!'.codeUnitAt(0) + i));
    bs.addAll(List.generate('¬'.codeUnitAt(0) - '¡'.codeUnitAt(0) + 1,
        (i) => '¡'.codeUnitAt(0) + i));
    bs.addAll(List.generate('ÿ'.codeUnitAt(0) - '®'.codeUnitAt(0) + 1,
        (i) => '®'.codeUnitAt(0) + i));

    final cs = List<int>.from(bs);
    var n = 0;
    for (var b = 0; b < 256; b++) {
      if (!bs.contains(b)) {
        bs.add(b);
        cs.add(256 + n);
        n++;
      }
    }

    final result = <int, String>{};
    for (var i = 0; i < bs.length; i++) {
      result[bs[i]] = String.fromCharCode(cs[i]);
    }
    return result;
  }
}

/// A BPE merge pair.
class _BpePair {
  const _BpePair(this.a, this.b);
  final String a;
  final String b;
}

/// Pre-tokenized constants for built-in visual content category prompts.
///
/// These avoid the need to load the BPE vocabulary at runtime for the common
/// case of using only built-in categories. Generated by running each prompt
/// string through the CLIP tokenizer.
class ClipBuiltInTokens {
  ClipBuiltInTokens._();

  // ============================================================
  // Nudity category — no CLIP prompts (NudeNet only)
  // ============================================================

  // ============================================================
  // Sexual Content — positive prompts
  // ============================================================

  /// "explicit sexual act"
  static final Int32List explicitSexualAct = _pad([
    49406, 6969, 6402, 1328, 49407,
  ]);

  /// "sexual intercourse"
  static final Int32List sexualIntercourse = _pad([
    49406, 6402, 22031, 49407,
  ]);

  // ============================================================
  // Sexual Content — negative prompts
  // ============================================================

  /// "people exercising"
  static final Int32List peopleExercising = _pad([
    49406, 1047, 26585, 49407,
  ]);

  /// "wrestling match"
  static final Int32List wrestlingMatch = _pad([
    49406, 14838, 1528, 49407,
  ]);

  // ============================================================
  // Kissing — positive prompts
  // ============================================================

  /// "two people kissing"
  static final Int32List twoPeopleKissing = _pad([
    49406, 1237, 1047, 25765, 49407,
  ]);

  /// "romantic kiss on the lips"
  static final Int32List romanticKissOnTheLips = _pad([
    49406, 6875, 6836, 525, 518, 10734, 49407,
  ]);

  // ============================================================
  // Kissing — negative prompts
  // ============================================================

  /// "two people talking face to face"
  static final Int32List twoPeopleTalkingFaceToFace = _pad([
    49406, 1237, 1047, 3823, 1933, 531, 1933, 49407,
  ]);

  /// "people hugging"
  static final Int32List peopleHugging = _pad([
    49406, 1047, 26360, 49407,
  ]);

  // ============================================================
  // Immodest Dress — positive prompts
  // ============================================================

  /// "woman in revealing clothing"
  static final Int32List womanInRevealingClothing = _pad([
    49406, 2308, 530, 15127, 5765, 49407,
  ]);

  /// "woman wearing bikini"
  static final Int32List womanWearingBikini = _pad([
    49406, 2308, 3448, 25591, 49407,
  ]);

  /// "person in underwear"
  static final Int32List personInUnderwear = _pad([
    49406, 2533, 530, 16529, 49407,
  ]);

  // ============================================================
  // Immodest Dress — negative prompts
  // ============================================================

  /// "person wearing normal clothing"
  static final Int32List personWearingNormalClothing = _pad([
    49406, 2533, 3448, 3622, 5765, 49407,
  ]);

  /// "person in business attire"
  static final Int32List personInBusinessAttire = _pad([
    49406, 2533, 530, 1782, 34033, 49407,
  ]);

  /// Pad token list to context length.
  static Int32List _pad(List<int> tokens) {
    final result = Int32List(ClipTokenizer.contextLength);
    for (var i = 0; i < tokens.length && i < result.length; i++) {
      result[i] = tokens[i];
    }
    return result;
  }

  /// Get pre-tokenized prompt embeddings for a built-in prompt string.
  /// Returns null if the prompt is not a known built-in.
  static Int32List? getPreTokenized(String prompt) {
    switch (prompt) {
      // Sexual content positive
      case 'explicit sexual act':
        return explicitSexualAct;
      case 'sexual intercourse':
        return sexualIntercourse;
      // Sexual content negative
      case 'people exercising':
        return peopleExercising;
      case 'wrestling match':
        return wrestlingMatch;
      // Kissing positive
      case 'two people kissing':
        return twoPeopleKissing;
      case 'romantic kiss on the lips':
        return romanticKissOnTheLips;
      // Kissing negative
      case 'two people talking face to face':
        return twoPeopleTalkingFaceToFace;
      case 'people hugging':
        return peopleHugging;
      // Immodest dress positive
      case 'woman in revealing clothing':
        return womanInRevealingClothing;
      case 'woman wearing bikini':
        return womanWearingBikini;
      case 'person in underwear':
        return personInUnderwear;
      // Immodest dress negative
      case 'person wearing normal clothing':
        return personWearingNormalClothing;
      case 'person in business attire':
        return personInBusinessAttire;
      default:
        return null;
    }
  }
}
