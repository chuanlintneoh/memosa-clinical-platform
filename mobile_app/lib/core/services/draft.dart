import 'dart:convert';
import 'dart:io';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

class DraftService {
  // static const _storage = FlutterSecureStorage();

  static Future<void> saveDrafts(
    String userId,
    List<Map<String, dynamic>> drafts,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/drafts_$userId.json');
    await file.writeAsString(jsonEncode(drafts));
  }

  static Future<List<Map<String, dynamic>>> loadDrafts(String userId) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/drafts_$userId.json');
    if (await file.exists()) {
      final content = await file.readAsString();
      return List<Map<String, dynamic>>.from(jsonDecode(content));
    }
    return [];
  }

  // Delete all drafts for user (optional helper)
  static Future<void> clearDrafts(String userId) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/drafts_$userId.json');
    if (await file.exists()) {
      await file.delete();
    }
  }
}
