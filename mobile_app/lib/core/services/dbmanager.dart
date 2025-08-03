import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/core/models/case.dart';
import 'package:mobile_app/core/services/storage.dart';
import 'package:mobile_app/core/utils/crypto.dart';
import 'package:uuid/uuid.dart';

class DbManagerService {
  static const String _baseUrl = "http://10.0.2.2:8000/dbmanager";

  static Future<String?> createCase({
    required String caseId,
    required PublicCaseModel publicData,
    required PrivateCaseModel privateData,
    required String systemRsa,
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception("User not logged in");

      // final caseId = const Uuid().v4();
      // final createdAt = DateTime.now().toIso8601String().replaceAll(":", "-");

      final Map<String, dynamic> privateDataJson = privateData.toJson();
      // print("1. Case Data: $privateDataJson");
      final newAesKey = CryptoUtils.generateAESKey();
      // print("2. New AES Key: $newAesKey");
      final String encryptedBlob = CryptoUtils.encryptCaseData(
        privateDataJson,
        newAesKey,
      );
      // print("3. Encrypted Case Data: $encryptedBlob");
      final decodedPublicRsa = CryptoUtils.decodePublicKeyFromPem(systemRsa);
      // print("4. Decoded Public RSA: $decodedPublicRsa");
      final String encryptedAesKey = CryptoUtils.encryptAESKey(
        newAesKey,
        decodedPublicRsa,
      );
      // print("5. Encrypted AES Key: $encryptedAesKey");
      final String downloadUrl = await StorageService.uploadEncryptedBlob(
        encryptedBlob: encryptedBlob,
        fileName:
            "${caseId}_${publicData.createdAt.toIso8601String().split('.').first.replaceAll("-", "").replaceAll(":", "")}.enc",
      );
      // print("6. Download URL: $downloadUrl");

      String encryptedComments = "NULL";
      if (publicData.additionalComments != null &&
          publicData.additionalComments!.trim().isNotEmpty) {
        encryptedComments = CryptoUtils.encryptString(
          publicData.additionalComments!,
          newAesKey,
        );
      }

      final url = Uri.parse("$_baseUrl/case/create?case_id=$caseId");

      final body = jsonEncode(
        CaseDocumentModel(
          publicData: publicData,
          encryptedBlobUrl: downloadUrl,
          encryptedComments: encryptedComments,
          encryptedAesKey: encryptedAesKey,
        ).toJson(),
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['case_id'] as String?;
      } else {
        throw Exception("Case creation failed: ${response.body}");
      }
    } catch (e) {
      throw Exception("Exception during case creation: $e");
    }
  }

  // static Future<Map<String, dynamic>?> retrieveCase() async {
  //   final downloadedBlob = await StorageService.downloadEncryptedBlob(downloadUrl);
  //   print("7. Downloaded Blob: $downloadedBlob");
  //   final decodedPrivateRsa = CryptoUtils.decodePrivateKeyFromPem(privateRsa);
  //   print("8. Decoded Private RSA: $decodedPrivateRsa");
  //   final decryptedAesKey = CryptoUtils.decryptAESKey(
  //     encryptedAesKey,
  //     decodedPrivateRsa,
  //   );
  //   print("9. Decrypted AES Key: $decryptedAesKey");
  //   final decryptedBlob = CryptoUtils.decryptCaseData(
  //     downloadedBlob,
  //     decryptedAesKey,
  //   );
  //   print("10. Decrypted Case Data: $decryptedBlob");
  // }
}
