import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/detection/local_runtime_manager.dart';

enum SearchDocumentKind {
  caption('caption'),
  vlmFinding('vlm_finding'),
  rationale('rationale'),
  transcriptSpan('transcript_span'),
  regionLabel('region_label'),
  userReviewCorrection('user_review_correction');

  const SearchDocumentKind(this.jsonValue);

  final String jsonValue;

  static SearchDocumentKind fromJson(String value) =>
      SearchDocumentKind.values.firstWhere(
        (kind) => kind.jsonValue == value,
        orElse: () =>
            throw ArgumentError('Unknown search document kind: $value'),
      );
}

class SearchDocument {
  SearchDocument({
    required this.id,
    required this.mediaId,
    required this.kind,
    required this.text,
    required this.startTime,
    required this.endTime,
    this.categoryId,
    this.severity,
    this.reviewed,
    List<String> sourceModels = const <String>[],
    List<String> supportingEvidenceIds = const <String>[],
    List<double>? embedding,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  })  : sourceModels = List.unmodifiable(_dedupeStrings(sourceModels)),
        supportingEvidenceIds =
            List.unmodifiable(_dedupeStrings(supportingEvidenceIds)),
        embedding = embedding == null ? null : List.unmodifiable(embedding),
        metadata = Map.unmodifiable(_normalizeJsonMap(metadata));

  factory SearchDocument.fromJson(Map<String, dynamic> json) => SearchDocument(
        id: json['id'] as String,
        mediaId: json['mediaId'] as String,
        kind: SearchDocumentKind.fromJson(json['kind'] as String),
        text: json['text'] as String,
        startTime: Duration(milliseconds: json['startTimeMs'] as int? ?? 0),
        endTime: Duration(milliseconds: json['endTimeMs'] as int? ?? 0),
        categoryId: json['categoryId'] as String?,
        severity: json['severity'] as String?,
        reviewed: json['reviewed'] as bool?,
        sourceModels:
            (json['sourceModels'] as List<dynamic>? ?? const <dynamic>[])
                .map((value) => value as String)
                .toList(growable: false),
        supportingEvidenceIds:
            (json['supportingEvidenceIds'] as List<dynamic>? ??
                    const <dynamic>[])
                .map((value) => value as String)
                .toList(growable: false),
        embedding: (json['embedding'] as List<dynamic>?)
            ?.map((value) => (value as num).toDouble())
            .toList(growable: false),
        metadata: Map<String, dynamic>.from(
          json['metadata'] as Map<dynamic, dynamic>? ??
              const <dynamic, dynamic>{},
        ),
      );

  final String id;
  final String mediaId;
  final SearchDocumentKind kind;
  final String text;
  final Duration startTime;
  final Duration endTime;
  final String? categoryId;
  final String? severity;
  final bool? reviewed;
  final List<String> sourceModels;
  final List<String> supportingEvidenceIds;
  final List<double>? embedding;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => {
        'id': id,
        'mediaId': mediaId,
        'kind': kind.jsonValue,
        'text': text,
        'startTimeMs': startTime.inMilliseconds,
        'endTimeMs': endTime.inMilliseconds,
        if (categoryId != null) 'categoryId': categoryId,
        if (severity != null) 'severity': severity,
        if (reviewed != null) 'reviewed': reviewed,
        'sourceModels': sourceModels,
        'supportingEvidenceIds': supportingEvidenceIds,
        if (embedding != null) 'embedding': embedding,
        'metadata': metadata,
      };

  SearchDocument copyWithEmbedding(List<double> embedding) => SearchDocument(
        id: id,
        mediaId: mediaId,
        kind: kind,
        text: text,
        startTime: startTime,
        endTime: endTime,
        categoryId: categoryId,
        severity: severity,
        reviewed: reviewed,
        sourceModels: sourceModels,
        supportingEvidenceIds: supportingEvidenceIds,
        embedding: embedding,
        metadata: metadata,
      );

  static String deterministicId({
    required String mediaId,
    required SearchDocumentKind kind,
    required String text,
    required Duration startTime,
    required Duration endTime,
    String? categoryId,
  }) {
    final canonical = jsonEncode({
      'mediaId': mediaId,
      'kind': kind.jsonValue,
      'text': text,
      'startTimeMs': startTime.inMilliseconds,
      'endTimeMs': endTime.inMilliseconds,
      'categoryId': categoryId,
    });
    return 'sd_${sha256.convert(utf8.encode(canonical)).toString().substring(0, 24)}';
  }
}

class SearchFilter {
  const SearchFilter({
    this.categoryIds = const <String>{},
    this.severities = const <String>{},
    this.reviewed,
    this.sourceModels = const <String>{},
    this.startTime,
    this.endTime,
  });

  final Set<String> categoryIds;
  final Set<String> severities;
  final bool? reviewed;
  final Set<String> sourceModels;
  final Duration? startTime;
  final Duration? endTime;

  bool matches(SearchDocument document) {
    if (categoryIds.isNotEmpty && !categoryIds.contains(document.categoryId)) {
      return false;
    }
    if (severities.isNotEmpty && !severities.contains(document.severity)) {
      return false;
    }
    if (reviewed != null && document.reviewed != reviewed) {
      return false;
    }
    if (sourceModels.isNotEmpty &&
        !document.sourceModels.any(sourceModels.contains)) {
      return false;
    }
    if (startTime != null || endTime != null) {
      final queryStart = startTime ?? Duration.zero;
      final queryEnd = endTime ?? const Duration(days: 999999);
      if (!_overlaps(
        document.startTime,
        document.endTime,
        queryStart,
        queryEnd,
      )) {
        return false;
      }
    }
    return true;
  }
}

class SearchResult {
  const SearchResult({
    required this.document,
    required this.score,
    required this.matchedTerms,
  });

  final SearchDocument document;
  final double score;
  final List<String> matchedTerms;

  Duration get startTime => document.startTime;

  Duration get endTime => document.endTime;
}

abstract interface class LocalEmbeddingProvider {
  ModelBundleManifest get modelManifest;

  int get dimension;

  Future<List<double>> embedText(String text);

  Future<List<double>> embedQuery(String query) => embedText(query);

  Future<List<List<double>>> embedBatch(List<String> texts) =>
      Future.wait(texts.map(embedText));
}

class HashLocalEmbeddingProvider implements LocalEmbeddingProvider {
  const HashLocalEmbeddingProvider({
    this.dimension = 64,
    this.modelManifest = _qwenEmbeddingManifest,
  });

  @override
  final int dimension;

  @override
  final ModelBundleManifest modelManifest;

  @override
  Future<List<double>> embedText(String text) async {
    final vector = List<double>.filled(dimension, 0);
    for (final token in tokenizeForFamilySafetySearch(text)) {
      final digest = sha256.convert(utf8.encode(token)).bytes;
      final index = digest.first % dimension;
      final sign = digest[1].isEven ? 1.0 : -1.0;
      vector[index] += sign;
    }
    return _l2Normalize(vector);
  }

  @override
  Future<List<double>> embedQuery(String query) => embedText(query);

  @override
  Future<List<List<double>>> embedBatch(List<String> texts) =>
      Future.wait(texts.map(embedText));
}

class LlamaServerEmbeddingException implements Exception {
  const LlamaServerEmbeddingException(this.message);

  final String message;

  @override
  String toString() => 'LlamaServerEmbeddingException: $message';
}

class LlamaServerEmbeddingProvider implements LocalEmbeddingProvider {
  LlamaServerEmbeddingProvider({
    required this.endpointUri,
    this.modelAlias = 'qwen3-embedding',
    this.dimension = 1024,
    this.modelManifest = _qwenEmbeddingManifest,
    this.maxBatchSize = 32,
    http.Client? httpClient,
    LocalRuntimeEndpointPolicy endpointPolicy =
        const LocalRuntimeEndpointPolicy(),
  }) : _httpClient = httpClient {
    final issues = endpointPolicy.validate(
      LocalRuntimeConfig(endpointUri: endpointUri.toString()),
    );
    if (issues.isNotEmpty) {
      throw LlamaServerEmbeddingException(issues.join('; '));
    }
    if (maxBatchSize < 1 || maxBatchSize > 32) {
      throw const LlamaServerEmbeddingException(
        'embedding batch size must be between 1 and 32',
      );
    }
  }

  static const queryInstructionPrefix =
      'Instruct: Given a family-safety video search query, retrieve relevant scene descriptions\nQuery: ';

  final Uri endpointUri;
  final String modelAlias;
  @override
  final int dimension;
  @override
  final ModelBundleManifest modelManifest;
  final int maxBatchSize;
  final http.Client? _httpClient;

  @override
  Future<List<double>> embedText(String text) async {
    final vectors = await embedBatch([text]);
    return vectors.single;
  }

  @override
  Future<List<double>> embedQuery(String query) =>
      embedText('$queryInstructionPrefix$query');

  @override
  Future<List<List<double>>> embedBatch(List<String> texts) async {
    if (texts.isEmpty) return const <List<double>>[];
    final vectors = <List<double>>[];
    for (var offset = 0; offset < texts.length; offset += maxBatchSize) {
      final end = min(offset + maxBatchSize, texts.length);
      vectors.addAll(await _postEmbeddingBatch(texts.sublist(offset, end)));
    }
    return vectors;
  }

  Future<List<List<double>>> _postEmbeddingBatch(List<String> texts) async {
    final uri = endpointUri.resolve('/v1/embeddings');
    const headers = {'content-type': 'application/json'};
    final body = jsonEncode({
      'model': modelAlias,
      'input': texts,
    });
    final response = _httpClient == null
        ? await http.post(uri, headers: headers, body: body)
        : await _httpClient.post(uri, headers: headers, body: body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw LlamaServerEmbeddingException(
        'embedding request failed with HTTP ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const LlamaServerEmbeddingException(
        'embedding response must be a JSON object',
      );
    }
    final data = decoded['data'];
    if (data is! List || data.length != texts.length) {
      throw LlamaServerEmbeddingException(
        'embedding response data length ${data is List ? data.length : '<invalid>'} did not match request length ${texts.length}',
      );
    }

    final indexed = <({int index, List<double> embedding})>[];
    for (var position = 0; position < data.length; position++) {
      final item = data[position];
      if (item is! Map) {
        throw const LlamaServerEmbeddingException(
          'embedding response data entries must be objects',
        );
      }
      final embedding = item['embedding'];
      if (embedding is! List || embedding.isEmpty) {
        throw const LlamaServerEmbeddingException(
          'embedding response entry is missing embedding vector',
        );
      }
      final indexValue = item['index'];
      indexed.add(
        (
          index: indexValue is num ? indexValue.toInt() : position,
          embedding: _l2Normalize(
            embedding.map((value) => (value as num).toDouble()).toList(),
          ),
        ),
      );
    }
    indexed.sort((a, b) => a.index.compareTo(b.index));
    return indexed.map((entry) => entry.embedding).toList(growable: false);
  }
}

abstract interface class LocalSearchIndex {
  Future<void> indexDocuments(Iterable<SearchDocument> documents);

  Future<List<SearchResult>> search(
    String query, {
    SearchFilter filter = const SearchFilter(),
    int limit = 20,
  });

  Future<void> clearMedia(String mediaId);
}

class JsonSearchIndexStore {
  JsonSearchIndexStore(this.file);

  final File file;

  Future<List<SearchDocument>> readDocuments() async {
    if (!file.existsSync()) return const <SearchDocument>[];
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! List) return const <SearchDocument>[];
    return decoded
        .whereType<Map<dynamic, dynamic>>()
        .map((json) => SearchDocument.fromJson(Map<String, dynamic>.from(json)))
        .toList(growable: false);
  }

  Future<void> writeDocuments(List<SearchDocument> documents) async {
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(
        documents.map((document) => document.toJson()).toList(),
      ),
    );
  }
}

class InMemoryLocalSearchIndex implements LocalSearchIndex {
  InMemoryLocalSearchIndex({
    LocalEmbeddingProvider? embeddingProvider,
    this.store,
    this.semanticWeight = 0.25,
  }) : embeddingProvider =
            embeddingProvider ?? const HashLocalEmbeddingProvider();

  final LocalEmbeddingProvider embeddingProvider;
  final JsonSearchIndexStore? store;
  final double semanticWeight;
  final Map<String, SearchDocument> _documentsById = {};

  Future<void> load() async {
    final persisted = await store?.readDocuments() ?? const <SearchDocument>[];
    _documentsById
      ..clear()
      ..addEntries(
        persisted.map((document) => MapEntry(document.id, document)),
      );
  }

  Future<void> save() async {
    await store?.writeDocuments(_sortedDocuments());
  }

  @override
  Future<void> indexDocuments(Iterable<SearchDocument> documents) async {
    final pending = documents.toList(growable: false);
    final needsEmbedding = <SearchDocument>[];
    for (final document in pending) {
      if (document.embedding == null) {
        needsEmbedding.add(document);
      } else {
        _documentsById[document.id] = document;
      }
    }

    if (needsEmbedding.isNotEmpty) {
      final embeddings = await embeddingProvider.embedBatch(
        needsEmbedding.map((document) => document.text).toList(growable: false),
      );
      if (embeddings.length != needsEmbedding.length) {
        throw StateError(
          'embedding provider returned ${embeddings.length} vectors for ${needsEmbedding.length} documents',
        );
      }
      for (var index = 0; index < needsEmbedding.length; index++) {
        final document = needsEmbedding[index].copyWithEmbedding(
          embeddings[index],
        );
        _documentsById[document.id] = document;
      }
    }
    await save();
  }

  @override
  Future<List<SearchResult>> search(
    String query, {
    SearchFilter filter = const SearchFilter(),
    int limit = 20,
  }) async {
    final queryTerms = tokenizeForFamilySafetySearch(query);
    if (queryTerms.isEmpty) return const <SearchResult>[];
    final queryEmbedding = await embeddingProvider.embedQuery(query);
    final results = <SearchResult>[];

    for (final document in _sortedDocuments()) {
      if (!filter.matches(document)) continue;
      final documentTerms = tokenizeForFamilySafetySearch(
        '${document.text} ${document.categoryId ?? ''} ${document.severity ?? ''}',
      );
      final matchedTerms =
          queryTerms.where(documentTerms.contains).toSet().toList();
      final lexicalScore = _lexicalScore(
        query: query,
        queryTerms: queryTerms,
        documentText: document.text,
        documentTerms: documentTerms,
      );
      final semanticScore = document.embedding == null
          ? 0.0
          : _cosineSimilarity(queryEmbedding, document.embedding!);
      final score = (lexicalScore * (1 - semanticWeight)) +
          (semanticScore * semanticWeight);
      if (lexicalScore > 0 || semanticScore >= 0.55) {
        results.add(
          SearchResult(
            document: document,
            score: score,
            matchedTerms: matchedTerms,
          ),
        );
      }
    }

    results.sort((a, b) {
      final score = b.score.compareTo(a.score);
      if (score != 0) return score;
      final start = a.startTime.compareTo(b.startTime);
      if (start != 0) return start;
      return a.document.id.compareTo(b.document.id);
    });
    return results.take(limit).toList(growable: false);
  }

  @override
  Future<void> clearMedia(String mediaId) async {
    _documentsById.removeWhere((_, document) => document.mediaId == mediaId);
    await save();
  }

  List<SearchDocument> _sortedDocuments() => _documentsById.values.toList()
    ..sort((a, b) {
      final media = a.mediaId.compareTo(b.mediaId);
      if (media != 0) return media;
      final start = a.startTime.compareTo(b.startTime);
      if (start != 0) return start;
      return a.id.compareTo(b.id);
    });
}

class FamilySafetySearchIndexer {
  const FamilySafetySearchIndexer();

  List<SearchDocument> buildDocuments({
    required String mediaId,
    Iterable<EvidenceRecord> evidenceRecords = const <EvidenceRecord>[],
    Iterable<PolicyFinding> policyFindings = const <PolicyFinding>[],
    Iterable<Detection> detections = const <Detection>[],
  }) {
    final documents = <SearchDocument>[];
    for (final record
        in evidenceRecords.where((record) => record.mediaId == mediaId)) {
      documents.addAll(_documentsFromEvidence(record));
    }
    for (final finding
        in policyFindings.where((finding) => finding.mediaId == mediaId)) {
      documents.addAll(_documentsFromPolicyFinding(finding));
    }
    for (final detection
        in detections.where((detection) => detection.mediaId == mediaId)) {
      documents.addAll(_documentsFromDetection(detection));
    }
    final byId = <String, SearchDocument>{};
    for (final document in documents) {
      if (document.text.trim().isNotEmpty) {
        byId[document.id] = document;
      }
    }
    return byId.values.toList(growable: false)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  List<SearchDocument> _documentsFromEvidence(EvidenceRecord record) {
    switch (record.type) {
      case EvidenceType.vlmCaption:
        return _documentsFromVlmCaption(record);
      case EvidenceType.transcriptSpan:
        return _documentsFromTranscriptSpan(record);
      case EvidenceType.groundedRegion:
      case EvidenceType.legacyNudenetRegion:
      case EvidenceType.modestyParserSignal:
        return _documentsFromRegion(record);
      case EvidenceType.vlmPolicyJson:
      case EvidenceType.legacyNsfwScore:
      case EvidenceType.profanityMatch:
      case EvidenceType.embeddingRecord:
        return const <SearchDocument>[];
    }
  }

  List<SearchDocument> _documentsFromVlmCaption(EvidenceRecord record) {
    final documents = <SearchDocument>[];
    final caption = record.payload['caption'];
    if (caption is String && caption.trim().isNotEmpty) {
      documents.add(
        _document(
          mediaId: record.mediaId,
          kind: SearchDocumentKind.caption,
          text: caption,
          startTime: record.provenance.startTime,
          endTime: record.provenance.endTime,
          sourceModels: _sourceModels(record),
          supportingEvidenceIds: [record.id],
          metadata: {'evidenceType': record.type.jsonValue},
        ),
      );
    }

    final findings = record.payload['findings'];
    if (findings is List) {
      for (final rawFinding in findings.whereType<Map<dynamic, dynamic>>()) {
        final finding = Map<String, dynamic>.from(rawFinding);
        final categoryId = finding['category'] as String?;
        final rationale = finding['rationale'] as String? ?? '';
        final text = [
          if (categoryId != null) _categoryDisplayName(categoryId),
          categoryId,
          rationale,
        ].whereType<String>().join(' ');
        documents.add(
          _document(
            mediaId: record.mediaId,
            kind: SearchDocumentKind.vlmFinding,
            text: text,
            startTime: _durationFromMs(finding['startTimeMs']) ??
                record.provenance.startTime,
            endTime: _durationFromMs(finding['endTimeMs']) ??
                record.provenance.endTime,
            categoryId: categoryId,
            severity: finding['severity'] as String?,
            reviewed: finding['needsReview'] == true ? false : null,
            sourceModels: _sourceModels(record),
            supportingEvidenceIds: [record.id],
            metadata: {'evidenceType': record.type.jsonValue},
          ),
        );
      }
    }
    return documents;
  }

  List<SearchDocument> _documentsFromTranscriptSpan(EvidenceRecord record) {
    final segment = record.payload['segment'];
    if (segment is! Map) return const <SearchDocument>[];
    final json = Map<String, dynamic>.from(segment);
    final text = json['text'] as String? ?? '';
    return [
      _document(
        mediaId: record.mediaId,
        kind: SearchDocumentKind.transcriptSpan,
        text: text,
        startTime:
            _durationFromMs(json['startTimeMs']) ?? record.provenance.startTime,
        endTime:
            _durationFromMs(json['endTimeMs']) ?? record.provenance.endTime,
        sourceModels: _sourceModels(record),
        supportingEvidenceIds: [record.id],
        metadata: {
          'segmentId': json['id'],
          'evidenceType': record.type.jsonValue,
        },
      ),
    ];
  }

  List<SearchDocument> _documentsFromRegion(EvidenceRecord record) {
    final region = record.payload['region'];
    if (region is! Map) return const <SearchDocument>[];
    final label = region['label'] as String? ?? '';
    final categoryId = record.payload['categoryId'] as String?;
    final startTime = _durationFromMs(record.payload['timestampMs']) ??
        record.provenance.startTime;
    final endTime = record.provenance.endTime > startTime
        ? record.provenance.endTime
        : startTime + const Duration(milliseconds: 1);
    return [
      _document(
        mediaId: record.mediaId,
        kind: SearchDocumentKind.regionLabel,
        text: [
          label,
          categoryId,
          if (categoryId != null) _categoryDisplayName(categoryId),
        ].whereType<String>().join(' '),
        startTime: startTime,
        endTime: endTime,
        categoryId: categoryId,
        sourceModels: _sourceModels(record),
        supportingEvidenceIds: [record.id],
        metadata: {'evidenceType': record.type.jsonValue},
      ),
    ];
  }

  List<SearchDocument> _documentsFromPolicyFinding(PolicyFinding finding) => [
        _document(
          mediaId: finding.mediaId,
          kind: SearchDocumentKind.rationale,
          text:
              '${finding.category.displayName} ${finding.category.id} ${finding.rationale}',
          startTime: finding.startTime,
          endTime: finding.endTime,
          categoryId: finding.category.id,
          severity: finding.severity.name,
          reviewed: false,
          sourceModels: finding.sourceModels,
          supportingEvidenceIds: finding.supportingEvidenceIds,
          metadata: {
            'policyFindingId': finding.id,
            'groundingStatus': finding.groundingStatus,
            'regionIds': finding.regionIds,
          },
        ),
      ];

  List<SearchDocument> _documentsFromDetection(Detection detection) {
    if (detection.userStatus == DetectionUserStatus.pending &&
        (detection.userNote == null || detection.userNote!.trim().isEmpty)) {
      return const <SearchDocument>[];
    }
    final categoryId = detection.metadata?['policyCategoryId'] as String? ??
        detection.visualContentCategoryId ??
        detection.type.name;
    return [
      _document(
        mediaId: detection.mediaId,
        kind: SearchDocumentKind.userReviewCorrection,
        text: [
          categoryId,
          detection.description,
          detection.userStatus.name,
          detection.userNote,
        ].whereType<String>().join(' '),
        startTime: detection.startTime,
        endTime: detection.endTime,
        categoryId: categoryId,
        severity: detection.metadata?['policySeverity'] as String?,
        reviewed: detection.isReviewed,
        sourceModels: _stringList(detection.metadata?['sourceModels']),
        supportingEvidenceIds:
            _stringList(detection.metadata?['supportingEvidenceIds']),
        metadata: {'detectionId': detection.id},
      ),
    ];
  }

  SearchDocument _document({
    required String mediaId,
    required SearchDocumentKind kind,
    required String text,
    required Duration startTime,
    required Duration endTime,
    String? categoryId,
    String? severity,
    bool? reviewed,
    List<String> sourceModels = const <String>[],
    List<String> supportingEvidenceIds = const <String>[],
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) =>
      SearchDocument(
        id: SearchDocument.deterministicId(
          mediaId: mediaId,
          kind: kind,
          text: text,
          startTime: startTime,
          endTime: endTime,
          categoryId: categoryId,
        ),
        mediaId: mediaId,
        kind: kind,
        text: text,
        startTime: startTime,
        endTime: endTime,
        categoryId: categoryId,
        severity: severity,
        reviewed: reviewed,
        sourceModels: sourceModels,
        supportingEvidenceIds: supportingEvidenceIds,
        metadata: metadata,
      );
}

Set<String> tokenizeForFamilySafetySearch(String text) {
  final normalized = text
      .toLowerCase()
      .replaceAll('_', ' ')
      .replaceAll(RegExp('[^a-z0-9]+'), ' ');
  final tokens = normalized
      .split(RegExp('\\s+'))
      .where((token) => token.length > 1)
      .expand(_expandToken)
      .toSet();
  return tokens;
}

Iterable<String> _expandToken(String token) sync* {
  final stemmed = token.endsWith('s') && token.length > 3
      ? token.substring(0, token.length - 1)
      : token;
  yield token;
  yield stemmed;
  for (final synonym in _familySafetySynonyms[stemmed] ?? const <String>{}) {
    yield synonym;
  }
}

double _lexicalScore({
  required String query,
  required Set<String> queryTerms,
  required String documentText,
  required Set<String> documentTerms,
}) {
  final matches = queryTerms.where(documentTerms.contains).length;
  if (matches == 0) return 0;
  final overlap = matches / queryTerms.length;
  final phraseBoost =
      documentText.toLowerCase().contains(query.toLowerCase()) ? 0.25 : 0.0;
  return (overlap + phraseBoost).clamp(0.0, 1.0);
}

double _cosineSimilarity(List<double> a, List<double> b) {
  if (a.length != b.length || a.isEmpty) return 0;
  var dot = 0.0;
  for (var index = 0; index < a.length; index++) {
    dot += a[index] * b[index];
  }
  return dot.clamp(-1.0, 1.0);
}

List<double> _l2Normalize(List<double> vector) {
  final norm =
      sqrt(vector.fold<double>(0, (sum, value) => sum + value * value));
  if (norm < 1e-12) return vector;
  return vector.map((value) => value / norm).toList(growable: false);
}

bool _overlaps(
  Duration aStart,
  Duration aEnd,
  Duration bStart,
  Duration bEnd,
) {
  final normalizedAEnd =
      aEnd > aStart ? aEnd : aStart + const Duration(milliseconds: 1);
  final normalizedBEnd =
      bEnd > bStart ? bEnd : bStart + const Duration(milliseconds: 1);
  return aStart < normalizedBEnd && normalizedAEnd > bStart;
}

Duration? _durationFromMs(Object? value) {
  if (value is! num) return null;
  return Duration(milliseconds: value.round());
}

List<String> _sourceModels(EvidenceRecord record) => [
      if (record.provenance.modelBundleId != null)
        record.provenance.modelBundleId!,
      if (record.provenance.modelBundleId == null) record.provenance.providerId,
    ];

String _categoryDisplayName(String categoryId) {
  for (final category in FamilySafetyPolicyCategory.values) {
    if (category.id == categoryId) return category.displayName;
  }
  return categoryId.replaceAll('_', ' ');
}

List<String> _stringList(Object? value) {
  if (value is! List) return const <String>[];
  return value.whereType<String>().toList(growable: false);
}

List<String> _dedupeStrings(Iterable<String> values) =>
    values.where((value) => value.trim().isNotEmpty).toSet().toList();

Map<String, dynamic> _normalizeJsonMap(Map<String, dynamic> value) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);

const _familySafetySynonyms = <String, Set<String>>{
  'blood': {'bleeding', 'injury', 'wound'},
  'bleeding': {'blood'},
  'fight': {'fighting', 'violence', 'violent', 'assault'},
  'fighting': {'fight', 'violence', 'violent'},
  'weapon': {'gun', 'knife', 'rifle', 'firearm', 'blade', 'weapons'},
  'weapons': {'weapon', 'gun', 'knife', 'rifle', 'firearm', 'blade'},
  'gun': {'weapon', 'weapons', 'firearm'},
  'knife': {'weapon', 'weapons', 'blade'},
  'revealing': {'immodest', 'exposed', 'clothing', 'clothes'},
  'clothes': {'clothing', 'revealing', 'immodest'},
  'clothing': {'clothes', 'revealing', 'immodest'},
  'exposed': {'exposure', 'bare', 'revealing'},
  'leg': {'legs', 'thigh', 'thighs'},
  'legs': {'leg', 'thigh', 'thighs'},
  'nudity': {'nude', 'explicit', 'naked'},
  'nude': {'nudity', 'explicit', 'naked'},
  'gore': {'graphic', 'blood'},
};

const _qwenEmbeddingManifest = ModelBundleManifest(
  modelId: 'qwen3_embedding_0_6b_gguf_q8',
  displayName: 'Qwen3 Embedding 0.6B GGUF Q8',
  vendor: 'Alibaba / Qwen',
  officialSourceRepo: 'Qwen/Qwen3-Embedding-0.6B-GGUF',
  officialRevision: 'main',
  license: ModelBundleLicense.apache20,
  commercialUse: CommercialUseStatus.allowed,
  acceptedTermsRequired: false,
  artifactType: ModelBundleArtifactType.officialGguf,
  artifactUri: 'hf://Qwen/Qwen3-Embedding-0.6B-GGUF',
  sha256: null,
  conversionRecipeId: null,
  runtime: ModelBundleRuntime.llamaCppServer,
  minVramGb: 0,
  recommendedVramGb: 1,
  targetGpuClass: ModelBundleCatalog.targetGpuClass,
  maxValidatedVramGb: ModelBundleCatalog.targetGpuVramGb,
  quantization: ModelBundleQuantization.q8_0,
  fitsRtx5070Validated: false,
  supportsVideoInput: false,
  supportsImageInput: false,
  supportsBoundingBoxes: false,
  supportsMasks: false,
  supportsPointLocalization: false,
  maxFramesPerChunk: 1,
  maxContextTokens: 8192,
  recommendedChunkSeconds: 1,
  knownFailureModes: <String>[
    'Text-only embedding model; search quality depends on VLM captions and findings.',
    'CPU smoke validation has not been recorded.',
  ],
  roles: <ModelBundleRole>[ModelBundleRole.embedding],
  approvalStatus: ModelBundleApprovalStatus.evaluationOnly,
  reviewNotes:
      'Official Qwen GGUF embedding candidate for local text-evidence search.',
  leaderboardSourcesReviewed: ModelBundleCatalog.reviewedLeaderboardSources,
  artifactFiles: <ModelBundleArtifactFile>[
    ModelBundleArtifactFile(
      path: 'Qwen3-Embedding-0.6B-Q8_0.gguf',
      sizeBytes: 639150592,
    ),
  ],
);
