import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'models.dart';

class HistoryStore {
  static const fileName = 'chat_history_mock.json';

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fileName');
  }

  Future<HistoryDocument?> load() async {
    final f = await _file();
    if (!await f.exists()) return null;
    final raw = await f.readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('History JSON must be an object');
    }
    return HistoryDocument.fromJson(decoded);
  }

  Future<void> save(HistoryDocument doc) async {
    final f = await _file();
    final raw = const JsonEncoder.withIndent('  ').convert(doc.toJson());
    await f.writeAsString(raw);
  }

  Future<void> resetToSample() async {
    await save(HistoryDocument.sample());
  }

  Future<String> exportJson(HistoryDocument doc) async {
    return const JsonEncoder.withIndent('  ').convert(doc.toJson());
  }

  Future<HistoryDocument> importJson(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('History JSON must be an object');
    }
    final doc = HistoryDocument.fromJson(decoded);
    await save(doc);
    return doc;
  }
}

