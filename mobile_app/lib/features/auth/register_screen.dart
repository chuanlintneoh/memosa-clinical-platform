import 'package:flutter/material.dart';
import 'package:mobile_app/core/models/user.dart';
import 'package:mobile_app/core/services/auth.dart';
import 'package:mobile_app/features/auth/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  UserRole? _role = UserRole.clinician;

  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      setState(() {
        _loading = false;
        _error = "Passwords do not match";
      });
      return;
    }

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
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 4,
                child: Image.asset('assets/images/logo_crmy.webp'),
              ),
              const SizedBox(height: 20),
              const Text("Register", style: TextStyle(fontSize: 24)),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Confirm Password",
                  border: OutlineInputBorder(),
                ),
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
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text("Register"),
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
    );
  }
}
