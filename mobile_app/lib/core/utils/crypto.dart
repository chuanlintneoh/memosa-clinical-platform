import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart';
// import 'package:collection/collection.dart';

class CryptoUtils {
  // Functions:
  // generate aes key
  // encrypt aes key with passphrase
  // decrypt aes key with passphrase
  // encrypt string (can be very long) using aes key (case data will be encoded to json string)
  // decrypt string (can be very long) using aes key (case data will be decoded to json)

  static Uint8List generateAESKey() {
    final rnd = Random.secure();
    return Uint8List.fromList(List<int>.generate(32, (_) => rnd.nextInt(256)));
  }

  /// Encrypt AES key with passphrase (PBKDF2 + AES-CBC)
  static Map<String, String> encryptAESKeyWithPassphrase(
    Uint8List aesKey,
    String passphrase,
  ) {
    final salt = _randomBytes(16);
    final derivedKey = _deriveKey(
      passphrase,
      salt,
      32,
    ); // actual key to encrypt AES key that is derived from passphrase and salt
    final iv = _randomBytes(16);

    final cipherText = _aesCbcEncrypt(aesKey, derivedKey, iv);

    return {
      'ciphertext': base64Encode(cipherText),
      'iv': base64Encode(iv),
      'salt': base64Encode(salt),
    };
  }

  /// Decrypt AES key with passphrase
  static Uint8List decryptAESKeyWithPassphrase(
    String encryptedAESKeyB64,
    String passphrase,
    String saltB64,
    String ivB64,
  ) {
    final encryptedAESKey = base64Decode(encryptedAESKeyB64);
    final salt = base64Decode(saltB64);
    final iv = base64Decode(ivB64);

    final derivedKey = _deriveKey(passphrase, salt, 32);

    return _aesCbcDecrypt(encryptedAESKey, derivedKey, iv);
  }

  /// Decrypt AES key with passphrase in background isolate (non-blocking)
  static Future<Uint8List> decryptAESKeyWithPassphraseAsync(
    String encryptedAESKeyB64,
    String passphrase,
    String saltB64,
    String ivB64,
  ) async {
    return compute(_decryptAESKeyIsolate, {
      'encryptedAESKeyB64': encryptedAESKeyB64,
      'passphrase': passphrase,
      'saltB64': saltB64,
      'ivB64': ivB64,
    });
  }

  static Uint8List _decryptAESKeyIsolate(Map<String, String> params) {
    return decryptAESKeyWithPassphrase(
      params['encryptedAESKeyB64']!,
      params['passphrase']!,
      params['saltB64']!,
      params['ivB64']!,
    );
  }

  /// Encrypt JSON string using AES key
  static Map<String, String> encryptString(String plainText, Uint8List aesKey) {
    // final jsonString = jsonEncode(jsonData);
    final iv = _randomBytes(16);

    final cipherText = _aesCbcEncrypt(
      Uint8List.fromList(utf8.encode(plainText)),
      aesKey,
      iv,
    );

    return {'ciphertext': base64Encode(cipherText), 'iv': base64Encode(iv)};
  }

  /// Decrypt JSON string using AES key
  static String decryptString(
    String encryptedDataB64,
    String ivB64,
    Uint8List aesKey,
  ) {
    final encryptedData = base64Decode(encryptedDataB64);
    final iv = base64Decode(ivB64);

    final plainBytes = _aesCbcDecrypt(encryptedData, aesKey, iv);
    final decryptedString = utf8.decode(plainBytes);

    return decryptedString;
    // return jsonDecode(jsonString);
  }

  /// Decrypt JSON string using AES key in background isolate (non-blocking)
  static Future<String> decryptStringAsync(
    String encryptedDataB64,
    String ivB64,
    Uint8List aesKey,
  ) async {
    return compute(_decryptStringIsolate, {
      'encryptedDataB64': encryptedDataB64,
      'ivB64': ivB64,
      'aesKey': aesKey,
    });
  }

  static String _decryptStringIsolate(Map<String, dynamic> params) {
    return decryptString(
      params['encryptedDataB64'] as String,
      params['ivB64'] as String,
      params['aesKey'] as Uint8List,
    );
  }

  // ======== Internal Helpers ========
  static Uint8List _deriveKey(String passphrase, Uint8List salt, int length) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, 100000, length));
    return pbkdf2.process(Uint8List.fromList(utf8.encode(passphrase)));
  }

  static Uint8List _aesCbcEncrypt(Uint8List data, Uint8List key, Uint8List iv) {
    final cipher =
        PaddedBlockCipherImpl(PKCS7Padding(), CBCBlockCipher(AESEngine()))
          ..init(
            true,
            PaddedBlockCipherParameters<ParametersWithIV<KeyParameter>, Null>(
              ParametersWithIV<KeyParameter>(KeyParameter(key), iv),
              null,
            ),
          );
    return cipher.process(data);
  }

  static Uint8List _aesCbcDecrypt(Uint8List data, Uint8List key, Uint8List iv) {
    final cipher =
        PaddedBlockCipherImpl(PKCS7Padding(), CBCBlockCipher(AESEngine()))
          ..init(
            false,
            PaddedBlockCipherParameters<ParametersWithIV<KeyParameter>, Null>(
              ParametersWithIV<KeyParameter>(KeyParameter(key), iv),
              null,
            ),
          );
    return cipher.process(data);
  }

  static Uint8List _randomBytes(int length) {
    final rnd = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => rnd.nextInt(256)),
    );
  }
}

// void main() {
//   final testPassword = "nothingbeatsajet2holiday";

//   // Key generation + encryption + decryption flow
//   final aes = CryptoUtils.generateAESKey();
//   print("Generated AES Key: ${base64Encode(aes)}");
//   final encryptAES = CryptoUtils.encryptAESKeyWithPassphrase(aes, testPassword);
//   print("Encrypted AES Key: ${encryptAES['ciphertext']}");
//   print("Salt: ${encryptAES['salt']}");
//   print("IV: ${encryptAES['iv']}");
//   final decryptAES = CryptoUtils.decryptAESKeyWithPassphrase(
//     encryptAES['ciphertext']!,
//     testPassword,
//     encryptAES['salt']!,
//     encryptAES['iv']!,
//   );
//   print("Decrypted AES Key: ${base64Encode(decryptAES)}");
//   print("Keys match: ${base64Encode(aes) == base64Encode(decryptAES)}");
//   print("");

//   // String encryption + decryption flow
//   final plainText = "Hello, World! I am Chuan Lin";
//   print("Plain Text: $plainText");
//   final encryptString = CryptoUtils.encryptString(plainText, aes);
//   print("Encrypted String: ${encryptString['ciphertext']}");
//   print("IV: ${encryptString['iv']}");
//   final decryptString = CryptoUtils.decryptString(
//     encryptString['ciphertext']!,
//     encryptString['iv']!,
//     aes,
//   );
//   print("Decrypted String: $decryptString");
//   print("Strings match: ${plainText == decryptString}");
//   print("");

//   Uint8List generateDummyBytes(int sizeInKB) {
//     final random = Random();
//     return Uint8List.fromList(
//       List<int>.generate(sizeInKB * 1024, (_) => random.nextInt(256)),
//     );
//   }

//   // Case encryption + decryption flow
//   final jsonData = {
//     "address":
//         "123 Example Street, Apartment 4B, Springfield, 11900, Example Country.",
//     "age": "20",
//     "attending_hospital": "Tan Tock Seng Hospital",
//     "chief_complaint": "Persistent headache and dizziness",
//     "consent_form": base64Encode(
//       generateDummyBytes(100),
//     ), // 100KB dummy consent form
//     "dob": "2004-12-07T00:00:00Z",
//     "ethnicity": "Chinese",
//     "gender": "MALE",
//     "idnum": "701204072039",
//     "idtype": "NRIC",
//     "lesion_clinical_presentation":
//         "Small round lesion on the left forearm, approx. 2cm in diameter.",
//     "medical_history": "No known chronic illnesses.",
//     "medication_history": "Occasional use of paracetamol.",
//     "name": "John Doe",
//     "phonenum": "60123456789",
//     "presenting_complaint_history":
//         "Symptoms started two weeks ago, worsening over the past three days.",
//     "images": List.generate(
//       9,
//       (_) => base64Encode(generateDummyBytes(200)),
//     ), // 9 dummy 200KB images
//   };
//   // print("Original Case Data: $jsonData");
//   final encryptCase = CryptoUtils.encryptString(jsonEncode(jsonData), aes);
//   // print("Encrypted Case Data: ${encryptCase['encrypted_string']}");
//   print("IV: ${encryptCase['iv']}");
//   final decryptCase = CryptoUtils.decryptString(
//     encryptCase['ciphertext']!,
//     encryptCase['iv']!,
//     aes,
//   );
//   // print("Decrypted Case Data: $decryptCase");
//   print("Case data matches: ${jsonEncode(jsonData) == decryptCase}");
//   final mapEquals = const DeepCollectionEquality().equals;
//   print("Parsed matches: ${mapEquals(jsonData, jsonDecode(decryptCase))}");
//   print("");
// }
