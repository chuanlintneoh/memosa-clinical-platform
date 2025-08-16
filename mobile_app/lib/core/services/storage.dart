import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

class StorageService {
  static Future<String> upload({
    required String? encrypted,
    required String fileName,
    required String path,
  }) async {
    if (encrypted == null) {
      return "NULL";
    }
    try {
      final encryptedBlobBytes = base64Decode(encrypted);
      final storageRef = FirebaseStorage.instance.ref().child(
        '$path/$fileName',
      );

      final uploadTask = await storageRef.putData(
        encryptedBlobBytes,
        SettableMetadata(contentType: 'application/octet-stream'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload: $e');
    }
  }

  static Future<String> download(String downloadUrl) async {
    try {
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        return base64Encode(response.bodyBytes);
      } else {
        throw Exception('Failed to download: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to download: $e');
    }
  }
}
