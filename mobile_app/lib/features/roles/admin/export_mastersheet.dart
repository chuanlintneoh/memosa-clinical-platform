import 'package:flutter/material.dart';
import 'package:mobile_app/core/services/dbmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExportMastersheetScreen extends StatefulWidget {
  const ExportMastersheetScreen({super.key});

  @override
  State<ExportMastersheetScreen> createState() =>
      _ExportMastersheetScreenState();
}

class _ExportMastersheetScreenState extends State<ExportMastersheetScreen> {
  final _emailController = TextEditingController();
  String? _userEmail;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("email");
    setState(() {
      _userEmail = email;
      if (email != null) {
        _emailController.text = email;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Export Mastersheet")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_userEmail != null) ...[
              Text(
                "Use your saved email or type another:",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : null,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text("Send to $_userEmail"),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.email),
              label: const Text("Open Email App"),
            ),
          ],
        ),
      ),
    );
  }
}
