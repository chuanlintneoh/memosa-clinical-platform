import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static Future<String> uploadEncryptedBlob({
    required String encryptedBlob,
    required String fileName,
  }) async {
    try {
      final encryptedBlobBytes = base64Decode(encryptedBlob);
      final storageRef = FirebaseStorage.instance.ref().child(
        'encrypted_blobs/$fileName',
      );

      final uploadTask = await storageRef.putData(
        encryptedBlobBytes,
        SettableMetadata(contentType: 'application/octet-stream'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload blob: $e');
    }
  }

  static Future<String> downloadEncryptedBlob(String downloadUrl) async {
    try {
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        return base64Encode(response.bodyBytes);
      } else {
        throw Exception('Failed to download blob: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to download blob: $e');
    }
  }
}
