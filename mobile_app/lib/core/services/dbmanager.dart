import 'dart:convert';
import 'dart:typed_data';

// import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/core/models/case.dart';
import 'package:mobile_app/core/services/storage.dart';
import 'package:mobile_app/core/utils/crypto.dart';

class DbManagerService {
  static final String _baseUrl = "http://10.0.2.2:8000/dbmanager";
  // static final String _baseUrl = "${dotenv.env['BACKEND_SERVER_URL']}/dbmanager";

  static Future<String?> createCase({
    required String caseId,
    required PublicCaseModel publicData,
    required PrivateCaseModel privateData,
  }) async {
    try {
      // final uid = FirebaseAuth.instance.currentUser?.uid;
      // if (uid == null) throw Exception("User not logged in");

      // final createdAt = DateTime.now().toIso8601String().replaceAll(":", "-");

      final newAesKey = CryptoUtils.generateAESKey();
      var encryptedData = CryptoUtils.encryptString(
        jsonEncode(privateData.toJson()),
        newAesKey,
      );
      final encryptedBlob = <String, String>{
        'url': await StorageService.upload(
          encrypted: encryptedData['ciphertext'],
          fileName:
              "${caseId}_${publicData.createdAt.toIso8601String().split('.').first.replaceAll('-', '').replaceAll(':', '')}.enc",
          path: "encrypted_blobs",
        ),
        'iv': encryptedData['iv'] ?? "NULL",
      };

      final encryptedAes = CryptoUtils.encryptAESKeyWithPassphrase(
        newAesKey,
        dotenv.env['PASSWORD'] ?? '',
      );

      final encryptedComments =
          (publicData.additionalComments != "NULL" &&
              publicData.additionalComments.trim().isNotEmpty)
          ? CryptoUtils.encryptString(
              publicData.additionalComments.trim(),
              newAesKey,
            )
          : {'ciphertext': "NULL", 'iv': "NULL"};

      final url = Uri.parse("$_baseUrl/case/create?case_id=$caseId");

      final body = jsonEncode(
        CaseCreateModel(
          publicData: publicData,
          encryptedAes: encryptedAes,
          encryptedBlob: encryptedBlob,
          encryptedComments: encryptedComments,
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

  static Future<Map<String, dynamic>> searchCase({
    required String caseId,
  }) async {
    // Study coordinator searches for a case
    var blob = "NULL";
    String comments = "NULL";
    Uint8List aes = Uint8List(0);

    try {
      final url = Uri.parse("$_baseUrl/case/get/$caseId");
      final response = await http.get(url);

      if (response.statusCode != 200) {
        return {"error": "Case not found"};
        // throw Exception("Case not found: ${response.body}");
      }

      final rawCase = jsonDecode(response.body);

      if (rawCase["encrypted_aes"] != null) {
        if (rawCase["encrypted_aes"]["ciphertext"] != "NULL" &&
            rawCase["encrypted_aes"]["iv"] != "NULL" &&
            rawCase["encrypted_aes"]["salt"] != "NULL") {
          final ciphertext = rawCase["encrypted_aes"]["ciphertext"];
          final iv = rawCase["encrypted_aes"]["iv"];
          final salt = rawCase["encrypted_aes"]["salt"];
          aes = CryptoUtils.decryptAESKeyWithPassphrase(
            ciphertext,
            dotenv.env['PASSWORD'] ?? '',
            salt,
            iv,
          );
          if (rawCase["encrypted_blob"] != null) {
            if (rawCase["encrypted_blob"]["url"] != "NULL" &&
                rawCase["encrypted_blob"]["iv"] != "NULL") {
              final url = rawCase["encrypted_blob"]["url"];
              final ivBlob = rawCase["encrypted_blob"]["iv"];
              final encryptedBlob = await StorageService.download(url);
              blob = CryptoUtils.decryptString(encryptedBlob, ivBlob, aes);
            }
          }
          if (rawCase["additional_comments"] != null) {
            if (rawCase["additional_comments"]["ciphertext"] != "NULL" &&
                rawCase["additional_comments"]["iv"] != "NULL") {
              comments = CryptoUtils.decryptString(
                rawCase["additional_comments"]["ciphertext"],
                rawCase["additional_comments"]["iv"],
                aes,
              );
            }
          }
        }
      }

      return {
        "case_id": caseId,
        "aes": aes,
        "case_data": CaseRetrieveModel.fromRaw(
          rawCase: rawCase,
          blob: blob,
          comments: comments,
        ),
      };
    } catch (e) {
      return {"error": "Exception during case search: $e"};
      // throw Exception("Exception during case search: $e");
    }
  }

  static Future<String?> editCase({
    required String caseId,
    required CaseEditModel caseData,
  }) async {
    // Study coordinator edit case (eg. add ground truth)
    try {
      final url = Uri.parse("$_baseUrl/case/edit?case_id=$caseId");
      final body = jsonEncode(caseData.toJson());
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
      throw Exception("Exception during case editing: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> getUndiagnosedCases({
    required String clinicianID,
  }) async {
    // Clinician retrieves undiagnosed cases
    try {
      final url = Uri.parse("$_baseUrl/cases/undiagnosed/$clinicianID");
      final response = await http.get(url);

      if (response.statusCode != 200) {
        return [
          {"error": "Case not found"},
        ];
        // throw Exception("Case not found: ${response.body}");
      }

      final rawCases = jsonDecode(response.body) as List;
      List<Map<String, dynamic>> results = [];

      for (var rawCase in rawCases) {
        try {
          var blob = "NULL";
          String comments = "NULL";
          Uint8List aes = Uint8List(0);
          final caseId = rawCase["case_id"] ?? "UNKNOWN";

          if (rawCase["encrypted_aes"] != null) {
            if (rawCase["encrypted_aes"]["ciphertext"] != "NULL" &&
                rawCase["encrypted_aes"]["iv"] != "NULL" &&
                rawCase["encrypted_aes"]["salt"] != "NULL") {
              final ciphertext = rawCase["encrypted_aes"]["ciphertext"];
              final iv = rawCase["encrypted_aes"]["iv"];
              final salt = rawCase["encrypted_aes"]["salt"];

              aes = CryptoUtils.decryptAESKeyWithPassphrase(
                ciphertext,
                dotenv.env['PASSWORD'] ?? '',
                salt,
                iv,
              );

              if (rawCase["encrypted_blob"] != null &&
                  rawCase["encrypted_blob"]["url"] != "NULL" &&
                  rawCase["encrypted_blob"]["iv"] != "NULL") {
                final url = rawCase["encrypted_blob"]["url"];
                final ivBlob = rawCase["encrypted_blob"]["iv"];
                final encryptedBlob = await StorageService.download(url);
                blob = CryptoUtils.decryptString(encryptedBlob, ivBlob, aes);
              }

              if (rawCase["additional_comments"] != null &&
                  rawCase["additional_comments"]["ciphertext"] != "NULL" &&
                  rawCase["additional_comments"]["iv"] != "NULL") {
                comments = CryptoUtils.decryptString(
                  rawCase["additional_comments"]["ciphertext"],
                  rawCase["additional_comments"]["iv"],
                  aes,
                );
              }
            }
          }

          results.add({
            "case_id": caseId,
            "aes": aes,
            "case_data": CaseRetrieveModel.fromRaw(
              rawCase: rawCase,
              blob: blob,
              comments: comments,
            ),
          });
        } catch (e) {
          results.add({
            "error": "Exception during case decryption: $e",
            "raw_case": rawCase,
          });
        }
      }
      return results;
    } catch (e) {
      return [
        {"error": "Exception during case retrieval: $e"},
      ];
      // throw Exception("Exception during case retrieval: $e");
    }
  }

  static Future<String> diagnoseCase({
    required String caseId,
    required CaseDiagnosisModel diagnoses,
  }) async {
    // Clinician diagnoses a case (clinical diagnosis + lesion type + low quality)
    try {
      final url = Uri.parse("$_baseUrl/case/diagnose?case_id=$caseId");
      final body = jsonEncode(diagnoses.toJson());
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['case_id'] as String;
      } else {
        throw Exception("Case diagnosis failed: ${response.body}");
      }
    } catch (e) {
      throw Exception("Exception during case diagnosis: $e");
    }
  }

  static Future<Map<String, dynamic>> exportBundle({
    required bool includeAll,
  }) async {
    // Admin exports bundle
    try {
      final url = Uri.parse("$_baseUrl/bundle/export?include_all=$includeAll");
      final response = await http.get(url);

      return jsonDecode(response.body);
    } catch (e) {
      throw Exception("Error exporting bundle: $e");
    }
  }
}
