import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:basic_utils/basic_utils.dart' as bu;
import 'dart:math';

class CryptoUtils {
  static AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAKeyPair({
    int bitLength = 2048,
  }) {
    final keyGen = RSAKeyGenerator()
      ..init(
        ParametersWithRandom(
          RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
          _secureRandom(),
        ),
      );
    return keyGen.generateKeyPair();
  }

  static String encodePublicKeyToPem(RSAPublicKey publicKey) {
    // for storing new public keys
    return bu.CryptoUtils.encodeRSAPublicKeyToPem(publicKey);
  }

  static RSAPublicKey decodePublicKeyFromPem(String publicPem) {
    // for retrieving public keys
    return bu.CryptoUtils.rsaPublicKeyFromPem(publicPem);
  }

  static String encodePrivateKeyToPem(RSAPrivateKey privateKey) {
    // for storing new private keys
    return bu.CryptoUtils.encodeRSAPrivateKeyToPem(privateKey);
  }

  static RSAPrivateKey decodePrivateKeyFromPem(String privatePem) {
    // for retrieving private keys
    return bu.CryptoUtils.rsaPrivateKeyFromPem(privatePem);
  }

  static String encryptPrivateKey(String privatePem, String password) {
    // for storing new private keys securely
    final key = _deriveKey(password);
    final iv = _generateIV();
    final cipher = CBCBlockCipher(AESEngine())
      ..init(true, ParametersWithIV(KeyParameter(key), iv));

    final padded = _pkcs7Pad(Uint8List.fromList(utf8.encode(privatePem)), 16);
    final encrypted = _processBlocks(cipher, padded);

    final result = Uint8List.fromList(iv + encrypted);
    return base64Encode(result);
  }

  static String decryptPrivateKey(String encryptedPem, String password) {
    // for retrieving private keys securely
    final data = base64Decode(encryptedPem);
    final iv = data.sublist(0, 16);
    final ciphertext = data.sublist(16);

    final key = _deriveKey(password);
    final cipher = CBCBlockCipher(AESEngine())
      ..init(false, ParametersWithIV(KeyParameter(key), iv));

    final decrypted = _processBlocks(cipher, ciphertext);
    final unpadded = _pkcs7Unpad(decrypted);
    return utf8.decode(unpadded);
  }

  static Uint8List generateAESKey() {
    final keyBytes = _secureRandom().nextBytes(32); // 256-bit key
    return Uint8List.fromList(keyBytes);
  }

  static String encryptAESKey(Uint8List aesKey, RSAPublicKey publicKey) {
    final cipher = OAEPEncoding(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
    final encrypted = cipher.process(aesKey);
    return base64Encode(encrypted);
  }

  static Uint8List decryptAESKey(
    String encryptedKey,
    RSAPrivateKey privateKey,
  ) {
    final encryptedBytes = base64Decode(encryptedKey);
    final cipher = OAEPEncoding(RSAEngine())
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    final decrypted = cipher.process(encryptedBytes);
    return Uint8List.fromList(decrypted);
  }

  static String encryptCaseData(
    Map<String, dynamic> caseData,
    Uint8List aesKey,
  ) {
    final iv = _generateIV();
    final cipher = CBCBlockCipher(AESEngine())
      ..init(true, ParametersWithIV(KeyParameter(aesKey), iv));

    final padded = _pkcs7Pad(
      Uint8List.fromList(utf8.encode(jsonEncode(caseData))),
      16,
    );
    final encrypted = _processBlocks(cipher, padded);

    final result = Uint8List.fromList(iv + encrypted);
    return base64Encode(result);
  }

  static Map<String, dynamic> decryptCaseData(
    String encryptedData,
    Uint8List aesKey,
  ) {
    final data = base64Decode(encryptedData);
    final iv = data.sublist(0, 16);
    final ciphertext = data.sublist(16);

    final cipher = CBCBlockCipher(AESEngine())
      ..init(false, ParametersWithIV(KeyParameter(aesKey), iv));

    final decrypted = _processBlocks(cipher, ciphertext);
    final unpadded = _pkcs7Unpad(decrypted);
    return jsonDecode(utf8.decode(unpadded));
  }

  static String encryptString(String data, Uint8List aesKey) {
    final iv = _generateIV();
    final cipher = CBCBlockCipher(AESEngine())
      ..init(true, ParametersWithIV(KeyParameter(aesKey), iv));

    final padded = _pkcs7Pad(Uint8List.fromList(utf8.encode(data)), 16);
    final encrypted = _processBlocks(cipher, padded);

    final result = Uint8List.fromList(iv + encrypted);
    return base64Encode(result);
  }

  static String decryptString(String encryptedData, Uint8List aesKey) {
    final data = base64Decode(encryptedData);
    final iv = data.sublist(0, 16);
    final ciphertext = data.sublist(16);

    final cipher = CBCBlockCipher(AESEngine())
      ..init(false, ParametersWithIV(KeyParameter(aesKey), iv));

    final decrypted = _processBlocks(cipher, ciphertext);
    final unpadded = _pkcs7Unpad(decrypted);
    return utf8.decode(unpadded);
  }

  static SecureRandom _secureRandom() {
    final secureRandom = FortunaRandom();
    final seed = Uint8List.fromList(
      List.generate(32, (i) => Random.secure().nextInt(256)),
    );
    secureRandom.seed(KeyParameter(seed));
    return secureRandom;
  }

  static Uint8List _deriveKey(String password) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    final salt = utf8.encode('memosa-salt');
    pbkdf2.init(Pbkdf2Parameters(Uint8List.fromList(salt), 1000, 32));
    return pbkdf2.process(utf8.encode(password));
  }

  static Uint8List _generateIV() {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(16, (_) => rng.nextInt(256)));
  }

  static Uint8List _processBlocks(BlockCipher cipher, Uint8List input) {
    final output = Uint8List(input.length);
    for (int offset = 0; offset < input.length;) {
      offset += cipher.processBlock(input, offset, output, offset);
    }
    return output;
  }

  static Uint8List _pkcs7Pad(Uint8List input, int blockSize) {
    final padLen = blockSize - (input.length % blockSize);
    final padded = Uint8List(input.length + padLen)..setAll(0, input);
    for (int i = input.length; i < padded.length; i++) {
      padded[i] = padLen;
    }
    return padded;
  }

  static Uint8List _pkcs7Unpad(Uint8List input) {
    final padLen = input.last;
    return input.sublist(0, input.length - padLen);
  }
}
