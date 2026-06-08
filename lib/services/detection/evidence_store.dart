import 'dart:convert';
import 'dart:io';

import 'package:kidslens_video_editor/data/models/models.dart';

abstract interface class EvidenceStore {
  Future<void> append(EvidenceRecord record);

  Future<void> appendAll(Iterable<EvidenceRecord> records);

  Future<List<EvidenceRecord>> readAll({
    String? mediaId,
    EvidenceType? type,
  });

  Future<void> clear({String? mediaId});
}

class JsonEvidenceStore implements EvidenceStore {
  JsonEvidenceStore(this.file);

  final File file;

  @override
  Future<void> append(EvidenceRecord record) => appendAll([record]);

  @override
  Future<void> appendAll(Iterable<EvidenceRecord> records) async {
    final existing = await readAll();
    final byId = <String, EvidenceRecord>{
      for (final record in existing) record.id: record,
    };
    for (final record in records) {
      byId[record.id] = record;
    }
    await _write(byId.values.toList(growable: false));
  }

  @override
  Future<List<EvidenceRecord>> readAll({
    String? mediaId,
    EvidenceType? type,
  }) async {
    if (!file.existsSync()) {
      return const <EvidenceRecord>[];
    }
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! List) {
      throw const FormatException('Evidence store root must be a JSON list.');
    }
    final records = decoded
        .map((value) => EvidenceRecord.fromJson(value as Map<String, dynamic>))
        .where((record) => mediaId == null || record.mediaId == mediaId)
        .where((record) => type == null || record.type == type)
        .toList(growable: false)
      ..sort(_compareEvidenceRecords);
    return records;
  }

  @override
  Future<void> clear({String? mediaId}) async {
    if (mediaId == null) {
      if (file.existsSync()) {
        file.deleteSync();
      }
      return;
    }
    final kept = (await readAll())
        .where((record) => record.mediaId != mediaId)
        .toList(growable: false);
    await _write(kept);
  }

  Future<void> _write(List<EvidenceRecord> records) async {
    records.sort(_compareEvidenceRecords);
    file.parent.createSync(recursive: true);
    final tempFile = File('${file.path}.tmp');
    const encoder = JsonEncoder.withIndent('  ');
    await tempFile.writeAsString(
      encoder.convert(records.map((record) => record.toJson()).toList()),
    );
    if (file.existsSync()) {
      file.deleteSync();
    }
    await tempFile.rename(file.path);
  }
}

int _compareEvidenceRecords(EvidenceRecord a, EvidenceRecord b) {
  final startCompare = a.provenance.startTime.compareTo(b.provenance.startTime);
  if (startCompare != 0) {
    return startCompare;
  }
  final typeCompare = a.type.jsonValue.compareTo(b.type.jsonValue);
  if (typeCompare != 0) {
    return typeCompare;
  }
  return a.id.compareTo(b.id);
}
