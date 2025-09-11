import 'package:flutter/material.dart';
import 'package:mobile_app/features/auth/home_screen.dart';
import 'package:mobile_app/features/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _userId;
  String? _email;
  String? _role;
  String? _name;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("userId");
    final email = prefs.getString("email");
    final role = prefs.getString("role");
    final name = prefs.getString("name");
    setState(() {
      _userId = userId;
      _email = email;
      _role = role;
      _name = name;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_role == null) {
      return const LoginScreen();
    }

    return HomeScreen(
      userId: _userId!,
      email: _email!,
      role: _role!,
      name: _name!,
    );
  }
}
