// List of case drafts saved locally, button for creating new case draft
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/features/roles/study_coordinator/create_case.dart';
import 'package:mobile_app/core/services/draft.dart';

class DraftCasesScreen extends StatefulWidget {
  const DraftCasesScreen({super.key});

  @override
  State<DraftCasesScreen> createState() => _DraftCasesScreenState();
}

class _DraftCasesScreenState extends State<DraftCasesScreen> {
  List<Map<String, dynamic>> _drafts = [];

  @override
  void initState() {
    super.initState();
    _loadDrafts();
  }

  Future<void> _loadDrafts() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final drafts = await DraftService.loadDrafts(userId);
    setState(() {
      _drafts = drafts;
    });
  }

  Future<void> _persistDrafts() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    await DraftService.saveDrafts(userId, _drafts);
  }

  void _openCreateCase({Map<String, dynamic>? draft, int? index}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateCaseScreen(draft: draft, draftIndex: index),
      ),
    );

    if (result != null) {
      setState(() {
        if (result['action'] == 'delete') {
          _drafts.removeAt(result['index']);
        } else if (result['action'] == 'save') {
          if (result['index'] != null) {
            _drafts[result['index']] = result['data'];
          } else {
            _drafts.add(result['data']);
          }
        } else if (result['action'] == 'submit') {
          if (result['index'] != null) {
            _drafts.removeAt(result['index']);
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Case submitted')));
        }
      });

      await _persistDrafts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Draft Cases")),
      body: _drafts.isEmpty
          ? const Center(child: Text("No draft cases yet."))
          : ListView.builder(
              itemCount: _drafts.length,
              itemBuilder: (context, index) {
                final draft = _drafts[index];
                return ListTile(
                  title: Text(draft['caseId'] ?? 'Unknown Case ID'),
                  subtitle: Text(
                    draft['createdAt'] ?? 'Unknown Creation Date Time',
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _openCreateCase(draft: draft, index: index),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateCase(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
