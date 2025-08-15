import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/core/models/user.dart';

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
    final user = RegisterUser(
      fullName: fullName,
      email: email,
      password: password,
      role: role,
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
