import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/core/models/user.dart';
import 'package:mobile_app/core/services/main.dart';

class AuthService {
  static const String _baseUrl = "http://10.0.2.2:8000/auth";
  // static final String _baseUrl = "${dotenv.env['BACKEND_SERVER_URL']}/auth";
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      final serverUp = await MainService.ping();
      if (!serverUp) {
        throw Exception("Server is unreachable. Please try again later.");
      }

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
        throw Exception(response.body);
      }
    } catch (e) {
      throw Exception("Registration failed: $e");
    }
  }

  static Future<String> authorize() async {
    final String? idToken = await _auth.currentUser?.getIdToken();
    if (idToken == null) {
      throw Exception("Failed to get authentication token.");
    }
    return 'Bearer $idToken';
  }

  static Future<Map<String, dynamic>?> loginUser({
    required LoginUser user,
  }) async {
    try {
      final serverUp = await MainService.ping();
      if (!serverUp) {
        throw Exception("Server is unreachable. Please try again later.");
      }

      await _auth.signInWithEmailAndPassword(
        email: user.email,
        password: user.password,
      );

      final String idToken = await authorize();

      final url = Uri.parse("$_baseUrl/login");
      final response = await http.get(url, headers: {'Authorization': idToken});

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception("Unauthorized: Invalid token.");
      } else {
        throw Exception("Server error: ${response.body}");
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception("No user found for this email.");
      } else if (e.code == 'wrong-password') {
        throw Exception("Incorrect password.");
      } else if (e.code == 'user-disabled') {
        throw Exception("This account has been disabled.");
      } else {
        throw Exception("Authentication error: ${e.message}");
      }
    } on SocketException {
      throw Exception("Network error: Please check your internet connection.");
    } catch (e) {
      throw Exception("Login failed: $e");
    }
  }

  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);

      return {
        "message":
            "Password reset email sent successfully if the email exists.",
      };
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        return {"error": "Invalid email address."};
      }
      return {
        "message":
            "Password reset email sent successfully if the email exists.",
      };
    } on SocketException {
      return {"error": "Network error: Please check your internet connection."};
    } catch (e) {
      // Always return success to prevent email enumeration attacks
      return {
        "message":
            "Password reset email sent successfully if the email exists.",
      };
    }
  }

  static Future<void> logout() async {
    await _auth.signOut();
  }

  static User? getCurrentUser() {
    return _auth.currentUser;
  }
}
