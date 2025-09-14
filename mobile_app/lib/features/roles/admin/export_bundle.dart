import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_app/core/services/dbmanager.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

class ExportBundleScreen extends StatefulWidget {
  const ExportBundleScreen({super.key});

  @override
  State<ExportBundleScreen> createState() => _ExportBundleScreenState();
}

class _ExportBundleScreenState extends State<ExportBundleScreen> {
  // final _emailController = TextEditingController();
  // String? _userEmail;
  bool _exported = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool includeAllFlag = false;
  final _timestampController = TextEditingController();
  final _expiryDurationController = TextEditingController(
    text: "[Defaults to 1 day]",
  );
  final _urlController = TextEditingController(
    text: "[Signed URL will appear here]",
  );
  final _passwordController = TextEditingController(
    text: "[Generated password will appear here]",
  );

  @override
  void initState() {
    super.initState();
    // _loadUserEmail();
  }

  // Future<void> _loadUserEmail() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final email = prefs.getString("email");
  //   setState(() {
  //     _userEmail = email;
  //     if (email != null) {
  //       _emailController.text = email;
  //     }
  //   });
  // }

  Future<void> _exportBundle() async {
    setState(() {
      _isLoading = true;
    });
    final results = await DbManagerService.exportBundle(
      includeAll: includeAllFlag,
    );

    if (results["status"] == "success") {
      _timestampController.text = results["timestamp"] ?? 'NULL';
      _expiryDurationController.text = results["expiry_days"] != null
          ? "${results["expiry_days"]} day(s)"
          : 'Not specified';
      _urlController.text = results["url"] ?? 'NULL';
      _passwordController.text = results["password"] ?? 'NULL';
      setState(() {
        _exported = true;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _errorMessage = results["error"] ?? 'An error occurred';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool readOnly = true,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: readOnly
            ? IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: controller.text));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("$label copied")));
                },
              )
            : null,
        border: readOnly ? const OutlineInputBorder() : null,
      ),
      validator: (value) =>
          value == null || value.isEmpty ? "Enter $label" : null,
    );
  }

  void _shareBundle() {
    final timestamp = _timestampController.text;
    final url = _urlController.text;
    final password = _passwordController.text;
    final expiryDuration = _expiryDurationController.text;

    if (url.isEmpty || url.startsWith('[')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "No valid URL to share, please try exporting a bundle first.",
          ),
        ),
      );
      return;
    }

    final shareText =
        '''
        📦 *Exported Bundle*
        ⌚ Timestamp: $timestamp
        🔗 URL: $url
        🔑 Password: $password
        ⏳ Expiry Duration: $expiryDuration
        ''';

    SharePlus.instance.share(
      ShareParams(text: shareText, subject: "Exported Bundle"),
    );
  }

  Future<void> _confirmAction({
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (result == true) {
      onConfirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Export Bundle")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Include patients' sensitive data?",
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Switch(
                      value: includeAllFlag,
                      onChanged: (val) {
                        setState(() => includeAllFlag = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              onPressed: _isLoading
                  ? null
                  : () {
                      _confirmAction(
                        title: "Confirm Export Bundle",
                        message:
                            "You are about to export a bundle ${includeAllFlag ? "including" : "excluding"} patients' sensitive data. Are you sure you want to proceed?",
                        onConfirm: _exportBundle,
                      );
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              label: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Export Bundle"),
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            if (_exported) ...[
              Text(
                "Bundle Details",
                style: Theme.of(context).textTheme.titleMedium,
              ),

              const SizedBox(height: 8),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildTextField(_timestampController, "Timestamp"),
                      const SizedBox(height: 12),

                      _buildTextField(
                        _expiryDurationController,
                        "Expiry Duration",
                      ),
                      const SizedBox(height: 12),

                      _buildTextField(_urlController, "Signed URL"),
                      const SizedBox(height: 12),

                      _buildTextField(_passwordController, "Password"),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                icon: const Icon(Icons.share),
                onPressed: _shareBundle,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                label: const Text("Share Exported Bundle"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
