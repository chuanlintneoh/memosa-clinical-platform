import 'package:flutter/material.dart';
import 'package:mobile_app/core/models/user.dart';
import 'package:mobile_app/core/services/auth.dart';
import 'package:mobile_app/core/services/main.dart';
import 'package:mobile_app/features/auth/home_screen.dart';
import 'package:mobile_app/features/auth/register_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String? _error;
  bool _serverUp = false;

  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pingServer();
  }

  Future<void> _pingServer() async {
    final result = await MainService.ping();
    setState(() {
      _serverUp = result;
    });
  }

  Future<void> _login() async {
    if (!_serverUp) {
      await _pingServer();
      return;
    }

    if (_loading) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await AuthService.loginUser(
        user: LoginUser(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        ),
      );

      if (result != null &&
          result.containsKey("uid") &&
          result.containsKey("email") &&
          result.containsKey("role") &&
          result.containsKey("name")) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("userId", result["uid"]);
        await prefs.setString("email", result["email"]);
        await prefs.setString("role", result["role"]);
        await prefs.setString("name", result["name"]);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userId: result["uid"],
              email: result["email"],
              role: result["role"],
              name: result["name"],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login failed. Please try again.")),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 4,
                  child: Image.asset('assets/images/logo_crmy.webp'),
                ),
                const SizedBox(height: 20),
                const Text("Login", style: TextStyle(fontSize: 24)),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Email is required";
                    }
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return "Enter a valid email";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Password is required";
                    }
                    if (value.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ElevatedButton(
                  onPressed: _serverUp
                      ? (_loading ? null : _login)
                      : _pingServer,
                  child: _serverUp
                      ? (_loading
                            ? const CircularProgressIndicator()
                            : const Text("Login"))
                      : const Text("Connect to Server"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: const Text("Don't have an account? Register"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
