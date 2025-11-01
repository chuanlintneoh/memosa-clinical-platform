// List of case drafts saved locally, button for creating new case draft
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/core/services/draft.dart';
import 'package:mobile_app/features/roles/study_coordinator/create_case.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final prefs = await SharedPreferences.getInstance();
    final String userId =
        prefs.getString("userId") ??
        FirebaseAuth.instance.currentUser?.uid ??
        "unknown";
    if (userId == "unknown") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User ID not found. Please log in.")),
      );
      return;
    }
    final drafts = await DraftService.loadDrafts(userId);
    setState(() {
      _drafts = drafts;
    });
  }

  Future<void> _persistDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final String userId =
        prefs.getString("userId") ??
        FirebaseAuth.instance.currentUser?.uid ??
        "unknown";
    if (userId == "unknown") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User ID not found. Please log in.")),
      );
      return;
    }
    await DraftService.saveDrafts(userId, _drafts);
  }

  void _openCreateCase({Map<String, dynamic>? draft, int? index}) async {
    final result = await Navigator.push<Map<String, dynamic>>(
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final crossAxisCount = isTablet ? (screenWidth >= 900 ? 3 : 2) : 1;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Draft Cases"), elevation: 0),
      body: _drafts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.drafts_outlined,
                    size: isTablet ? 120 : 80,
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "No draft cases yet",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Tap the + button to create a new case",
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                if (isTablet) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _drafts.length,
                    itemBuilder: (context, index) {
                      final draft = _drafts[index];
                      return _buildDraftCard(draft, index, colorScheme);
                    },
                  );
                } else {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _drafts.length,
                    itemBuilder: (context, index) {
                      final draft = _drafts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildDraftCard(draft, index, colorScheme),
                      );
                    },
                  );
                }
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateCase(),
        icon: const Icon(Icons.add),
        label: Text(isTablet ? "Create New Case" : "New"),
        elevation: 4,
      ),
    );
  }

  Widget _buildDraftCard(
    Map<String, dynamic> draft,
    int index,
    ColorScheme colorScheme,
  ) {
    final caseId = draft['caseId'] ?? 'Unknown Case ID';
    final createdAt = draft['createdAt'] ?? 'Unknown Creation Date Time';
    final patientName = draft['name'] ?? '';

    String formattedDate = createdAt;
    try {
      final dateTime = DateTime.parse(createdAt);
      formattedDate =
          '${dateTime.day}/${dateTime.month}/${dateTime.year} '
          '${dateTime.hour.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      // Keep original string if parsing fails
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openCreateCase(draft: draft, index: index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      caseId,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (patientName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        patientName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.edit_outlined, color: colorScheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
