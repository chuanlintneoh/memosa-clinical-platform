import 'package:flutter/material.dart';
import 'package:mobile_app/core/models/user.dart';
import 'package:mobile_app/core/services/auth.dart';
import 'package:mobile_app/core/services/main.dart';
import 'package:mobile_app/features/auth/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _loading = false;
  String? _error;
  bool _serverUp = false;

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  UserRole? _role = UserRole.clinician;

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

  Future<void> _register() async {
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
      final result = await AuthService.registerUser(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: _role!,
      );

      if (result.containsKey("uid") &&
          result.containsKey("email") &&
          result.containsKey("name") &&
          result.containsKey("role")) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registration successful, please log in"),
          ),
        );

        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        setState(() => _role = UserRole.clinician);
      } else {
        setState(() => _error = "Registration failed");
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
                const Text("Register", style: TextStyle(fontSize: 24)),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Full Name",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Full name is required";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

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
                const SizedBox(height: 12),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Confirm Password",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please confirm your password";
                    }
                    if (value.trim() != _passwordController.text.trim()) {
                      return "Passwords do not match";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                const Text("Select Role:"),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Radio<UserRole>(
                          value: UserRole.clinician,
                          groupValue: _role,
                          onChanged: (val) => setState(() => _role = val),
                        ),
                        const Text("Clinician"),
                      ],
                    ),
                    Row(
                      children: [
                        Radio<UserRole>(
                          value: UserRole.studyCoordinator,
                          groupValue: _role,
                          onChanged: (val) => setState(() => _role = val),
                        ),
                        const Text("Study Coordinator"),
                      ],
                    ),
                    Row(
                      children: [
                        Radio<UserRole>(
                          value: UserRole.admin,
                          groupValue: _role,
                          onChanged: (val) => setState(() => _role = val),
                        ),
                        const Text("Admin"),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),

                ElevatedButton(
                  onPressed: _serverUp
                      ? (_loading ? null : _register)
                      : _pingServer,
                  child: _serverUp
                      ? (_loading
                            ? const CircularProgressIndicator()
                            : const Text("Register"))
                      : const Text("Connect to Server"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: const Text("Already have an account? Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
