import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/core/models/user.dart';
import 'package:mobile_app/core/utils/crypto.dart';

class AuthService {
  static const String _baseUrl = "http://10.0.2.2:8000/auth";
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final url = Uri.parse("$_baseUrl/register");
    String? publicRsa;
    String? privateRsa;

    if (role == UserRole.clinician) {
      final keyPair = CryptoUtils.generateRSAKeyPair();
      final publicPem = CryptoUtils.encodePublicKeyToPem(keyPair.publicKey);
      final privatePem = CryptoUtils.encodePrivateKeyToPem(keyPair.privateKey);
      final encryptedPrivatePem = CryptoUtils.encryptPrivateKey(
        privatePem,
        password,
      );
      publicRsa = publicPem;
      privateRsa = encryptedPrivatePem;
    }
    final user = RegisterUser(
      fullName: fullName,
      email: email,
      password: password,
      role: role.toApiValue(),
      publicRsa: role == UserRole.clinician ? publicRsa : null,
      privateRsa: role == UserRole.clinician ? privateRsa : null,
    );
    final body = jsonEncode(user.toJson());

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Registration failed: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>?> loginUser({
    required LoginUser user,
  }) async {
    final url = Uri.parse("$_baseUrl/login");

    final UserCredential userCredential = await _auth
        .signInWithEmailAndPassword(email: user.email, password: user.password);
    final String? idToken = await userCredential.user!.getIdToken(true);

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $idToken'},
    );

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);

      if (userData['role'] == 'clinician') {
        // final privateKey = CryptoUtils.decodePrivateKeyFromPem(
        //   CryptoUtils.decryptPrivateKey(userData['private_rsa'], user.password),
        // );
        final privateKey = CryptoUtils.decryptPrivateKey(
          userData['private_rsa'],
          user.password,
        );
        userData['private_rsa'] = privateKey;
      } else if (userData['role'] == 'study_coordinator' ||
          userData['role'] == 'admin') {
        final privateKey = CryptoUtils.decryptPrivateKey(
          userData['private_rsa'],
          dotenv.env['PRIVATE_KEY_PASSWORD'] ?? '',
        );
        userData['private_rsa'] = privateKey;
      }

      // userData['public_rsa'] = CryptoUtils.decodePublicKeyFromPem(
      //   userData['public_rsa'],
      // );
      return userData;
    } else {
      throw Exception("Login failed: ${response.body}");
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
