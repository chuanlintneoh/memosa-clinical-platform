import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/services/dbmanager.dart';

class CasesListScreen extends StatefulWidget {
  const CasesListScreen({super.key});

  @override
  State<CasesListScreen> createState() => _CasesListScreenState();
}

class _CasesListScreenState extends State<CasesListScreen> {
  bool _isLoading = false;
  bool _isLoadingMore = false;
  List<Map<String, dynamic>> _cases = [];
  String? _nextCursor;
  bool _hasMore = false;
  String? _errorMessage;
  bool _hasLoadedOnce = false;

  // Filter state
  String _selectedDateRange = 'all';
  bool _createdByMe = false;
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    // Don't load cases automatically - wait for user to apply filters
  }

  Future<void> _loadCases({bool loadMore = false}) async {
    if (_isLoading || _isLoadingMore) return;

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _cases = [];
        _nextCursor = null;
        _hasMore = false;
      }
      _errorMessage = null;
    });

    try {
      String? dateRange;
      String? customStart;
      String? customEnd;

      if (_selectedDateRange != 'all') {
        if (_selectedDateRange == 'custom') {
          dateRange = 'custom';
          if (_customStartDate != null && _customEndDate != null) {
            customStart = DateFormat('yyyy-MM-dd').format(_customStartDate!);
            customEnd = DateFormat('yyyy-MM-dd').format(_customEndDate!);
          }
        } else {
          dateRange = _selectedDateRange;
        }
      }

      final result = await DbManagerService.listCases(
        dateRange: dateRange,
        customStart: customStart,
        customEnd: customEnd,
        createdByMe: _createdByMe,
        limit: 5,
        startAfterId: loadMore ? _nextCursor : null,
      );

      final newCases = (result['cases'] as List).cast<Map<String, dynamic>>();

      setState(() {
        if (loadMore) {
          _cases.addAll(newCases);
        } else {
          _cases = newCases;
        }
        _nextCursor = result['next_cursor'];
        _hasMore = result['has_more'] ?? false;
        _hasLoadedOnce = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load cases: $e';
        _hasLoadedOnce = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _applyFilters() {
    _loadCases(loadMore: false);
  }

  void _navigateToEditCase(Map<String, dynamic> caseData) {
    Navigator.pushNamed(
      context,
      '/study_coordinator/edit_case',
      arguments: caseData,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Cases'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Filters section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Date range dropdown
                Row(
                  children: [
                    const Text('Date Range: '),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedDateRange,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('All Time'),
                          ),
                          DropdownMenuItem(
                            value: 'today',
                            child: Text('Today'),
                          ),
                          DropdownMenuItem(
                            value: 'this_week',
                            child: Text('This Week'),
                          ),
                          DropdownMenuItem(
                            value: 'this_month',
                            child: Text('This Month'),
                          ),
                          DropdownMenuItem(
                            value: 'custom',
                            child: Text('Custom Range'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedDateRange = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Custom date range pickers
                if (_selectedDateRange == 'custom') ...[
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _customStartDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                _customStartDate = picked;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Start Date',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            child: Text(
                              _customStartDate != null
                                  ? DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(_customStartDate!)
                                  : 'Select date',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _customEndDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setState(() {
                                _customEndDate = picked;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'End Date',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            child: Text(
                              _customEndDate != null
                                  ? DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(_customEndDate!)
                                  : 'Select date',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Created by me checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _createdByMe,
                      onChanged: (value) {
                        setState(() {
                          _createdByMe = value ?? false;
                        });
                      },
                    ),
                    const Text('Created by me'),
                  ],
                ),
                const SizedBox(height: 12),

                // Apply filters button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _applyFilters,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Cases list
          Expanded(child: _buildCasesList()),
        ],
      ),
    );
  }

  Widget _buildCasesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadCases(loadMore: false),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_cases.isEmpty) {
      if (!_hasLoadedOnce) {
        // Initial state - haven't applied filters yet
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.filter_list, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Apply filters to view cases',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select date range and click "Apply Filters"',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        );
      }

      // Loaded but no results
      return const Center(
        child: Text(
          'No cases found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cases.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _cases.length) {
          // Load more button
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: _isLoadingMore
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () => _loadCases(loadMore: true),
                      child: const Text('Load More'),
                    ),
            ),
          );
        }

        final caseData = _cases[index];
        final caseId = caseData['case_id'] ?? 'Unknown';
        final submittedAt = caseData['submitted_at'];

        String formattedDate = 'Not submitted';
        if (submittedAt != null) {
          try {
            // Parse Firestore timestamp
            if (submittedAt is Map && submittedAt.containsKey('_seconds')) {
              final timestamp = submittedAt['_seconds'] as int;
              final date = DateTime.fromMillisecondsSinceEpoch(
                timestamp * 1000,
              );
              formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(date);
            } else if (submittedAt is String) {
              final date = DateTime.parse(submittedAt);
              formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(date);
            }
          } catch (e) {
            formattedDate = 'Invalid date';
          }
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          child: InkWell(
            onTap: () => _navigateToEditCase(caseData),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Case ID: $caseId',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Submitted: $formattedDate',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
