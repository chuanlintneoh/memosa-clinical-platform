// List of undiagnosed cases, button for refreshing list
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/core/services/dbmanager.dart';
import 'package:mobile_app/features/roles/clinician/diagnose_case.dart';

class UndiagnosedCasesScreen extends StatefulWidget {
  const UndiagnosedCasesScreen({super.key});

  @override
  State<UndiagnosedCasesScreen> createState() => _UndiagnosedCasesScreenState();
}

class _UndiagnosedCasesScreenState extends State<UndiagnosedCasesScreen> {
  bool _isLoading = false;
  String? _message;
  final List<Map<String, dynamic>> _cases = [];

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  Future<void> _loadCases() async {
    try {
      setState(() {
        _isLoading = true;
        _cases.clear();
      });

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load cases, please try log in again."),
          ),
        );
        setState(() {
          _isLoading = false;
          _message = "Failed to load cases, please try log in again.";
        });
        return;
      }
      final results = await DbManagerService.getUndiagnosedCases(
        clinicianID: userId,
      );

      for (Map<String, dynamic> result in results) {
        if (!result.containsKey("error")) {
          _cases.add(result);
        } else {}
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading undiagnosed cases: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openDiagnoseCase({
    required Map<String, dynamic> caseInfo,
    required int index,
  }) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            DiagnoseCaseScreen(caseInfo: caseInfo, caseIndex: index),
      ),
    );

    if (result != null) {
      setState(() {
        if (result['action'] == 'diagnosed') {
          if (result['index'] != null) {
            _cases.removeAt(result['index']);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Undiagnosed Cases")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cases.isEmpty
          ? Center(
              child: Text(
                _message ?? "All cases are diagnosed. Refresh to check again.",
              ),
            )
          : ListView.builder(
              itemCount: _cases.length,
              itemBuilder: (context, index) {
                final caseInfo = _cases[index];
                return ListTile(
                  title: Text(caseInfo['case_id'] ?? 'Unknown Case ID'),
                  subtitle: Text(
                    caseInfo['case_data'].createdAt ??
                        'Unknown Creation Date Time',
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: () =>
                      _openDiagnoseCase(caseInfo: caseInfo, index: index),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _isLoading ? null : _loadCases(),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
