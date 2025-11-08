import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_app/core/models/user.dart';
import 'package:mobile_app/core/services/invite_code.dart';
import 'package:share_plus/share_plus.dart';

class InviteCodeManagerScreen extends StatefulWidget {
  const InviteCodeManagerScreen({super.key});

  @override
  State<InviteCodeManagerScreen> createState() =>
      _InviteCodeManagerScreenState();
}

class _InviteCodeManagerScreenState extends State<InviteCodeManagerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  UserRole? _selectedRole;
  int _maxUses = 1;
  int _expiresInDays = 30;
  bool _isGenerating = false;
  String? _error;
  Map<String, dynamic>? _generatedCode;

  List<Map<String, dynamic>> _inviteCodes = [];
  bool _isLoadingCodes = false;

  @override
  void initState() {
    super.initState();
    _loadInviteCodes();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadInviteCodes() async {
    setState(() {
      _isLoadingCodes = true;
      _error = null;
    });

    try {
      final codes = await InviteCodeService.listMyInviteCodes();
      setState(() {
        _inviteCodes = codes;
        _isLoadingCodes = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingCodes = false;
      });
    }
  }

  Future<void> _generateInviteCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGenerating = true;
      _error = null;
      _generatedCode = null;
    });

    try {
      final result = await InviteCodeService.generateInviteCode(
        restrictedEmail: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        restrictedRole: _selectedRole?.toApiValue(),
        maxUses: _maxUses,
        expiresInDays: _expiresInDays,
      );

      setState(() {
        _generatedCode = result;
        _isGenerating = false;
      });

      // Clear form
      _emailController.clear();
      setState(() {
        _selectedRole = null;
        _maxUses = 1;
        _expiresInDays = 30;
      });

      // Reload the list
      _loadInviteCodes();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invite code generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isGenerating = false;
      });
    }
  }

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label copied to clipboard')),
      );
    }
  }

  Future<void> _shareInviteCode(Map<String, dynamic> code) async {
    final codeText = code['code'] as String;
    final expiresAt = code['expires_at'] as String;
    final restrictedEmail = code['restricted_email'] as String?;
    final restrictedRole = code['restricted_role'] as String?;
    final maxUses = code['max_uses'] as int;

    String shareText = '''
Invite Code: $codeText

Expires: $expiresAt
Max Uses: ${maxUses == 0 ? 'Unlimited' : maxUses}
''';

    if (restrictedEmail != null) {
      shareText += 'Restricted to: $restrictedEmail\n';
    }

    if (restrictedRole != null) {
      shareText += 'Role: $restrictedRole\n';
    }

    shareText += '\nUse this code to register for the MeMoSA Clinical Platform.';

    SharePlus.instance.share(
      ShareParams(text: shareText, subject: 'MeMoSA Invite Code'),
    );
  }

  Future<void> _revokeCode(String code) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Invite Code'),
        content: Text('Are you sure you want to revoke code: $code?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await InviteCodeService.revokeInviteCode(code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invite code revoked successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      _loadInviteCodes();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite Code Manager'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Generate Invite Codes',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create invite codes for new users to register',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 32),

                // Generate Form Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Email restriction (optional)
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Restrict to Email (Optional)',
                              hintText: 'Leave empty for no restriction',
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              helperText:
                                  'If specified, only this email can use the code',
                            ),
                            validator: (value) {
                              if (value != null &&
                                  value.trim().isNotEmpty &&
                                  !RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                      .hasMatch(value.trim())) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Role restriction (optional)
                          DropdownButtonFormField<UserRole>(
                            value: _selectedRole,
                            decoration: InputDecoration(
                              labelText: 'Restrict to Role (Optional)',
                              prefixIcon:
                                  const Icon(Icons.admin_panel_settings),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              helperText:
                                  'If specified, code only works for this role',
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('No restriction'),
                              ),
                              ...UserRole.values.map((role) {
                                return DropdownMenuItem(
                                  value: role,
                                  child: Text(_roleToDisplayName(role)),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedRole = value);
                            },
                          ),
                          const SizedBox(height: 16),

                          // Max uses
                          TextFormField(
                            initialValue: _maxUses.toString(),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Maximum Uses',
                              prefixIcon: const Icon(Icons.people_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              helperText: 'Enter 0 for unlimited uses',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              final num = int.tryParse(value.trim());
                              if (num == null || num < 0) {
                                return 'Must be 0 or greater';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              final num = int.tryParse(value.trim());
                              if (num != null) {
                                _maxUses = num;
                              }
                            },
                          ),
                          const SizedBox(height: 16),

                          // Expires in days
                          TextFormField(
                            initialValue: _expiresInDays.toString(),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Expires in Days',
                              prefixIcon: const Icon(Icons.calendar_today),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              helperText: 'Days until code expires',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              final num = int.tryParse(value.trim());
                              if (num == null || num < 1) {
                                return 'Must be at least 1 day';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              final num = int.tryParse(value.trim());
                              if (num != null) {
                                _expiresInDays = num;
                              }
                            },
                          ),
                          const SizedBox(height: 24),

                          // Error message
                          if (_error != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: theme.colorScheme.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: TextStyle(
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Generate button
                          FilledButton.icon(
                            onPressed: _isGenerating ? null : _generateInviteCode,
                            icon: _isGenerating
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.add),
                            label: Text(
                              _isGenerating
                                  ? 'Generating...'
                                  : 'Generate Invite Code',
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Generated code display
                if (_generatedCode != null) ...[
                  const SizedBox(height: 24),
                  Card(
                    elevation: 4,
                    color: theme.colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Code Generated Successfully!',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildCodeField(
                            'Invite Code',
                            _generatedCode!['code'],
                            Icons.key,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.tonalIcon(
                                  onPressed: () => _copyToClipboard(
                                    _generatedCode!['code'],
                                    'Invite code',
                                  ),
                                  icon: const Icon(Icons.copy),
                                  label: const Text('Copy Code'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () =>
                                      _shareInviteCode(_generatedCode!),
                                  icon: const Icon(Icons.share),
                                  label: const Text('Share'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // List of existing codes
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Invite Codes',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: _loadInviteCodes,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_isLoadingCodes)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_inviteCodes.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No invite codes yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...List.generate(_inviteCodes.length, (index) {
                    final code = _inviteCodes[index];
                    return _buildCodeCard(code, theme);
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCodeField(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeCard(Map<String, dynamic> code, ThemeData theme) {
    final isActive = code['is_active'] as bool;
    final isExpired = code['is_expired'] as bool;
    final codeText = code['code'] as String;
    final timesUsed = code['times_used'] as int;
    final maxUses = code['max_uses'] as int;
    final restrictedEmail = code['restricted_email'] as String?;
    final restrictedRole = code['restricted_role'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            codeText,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 2,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!isActive)
                        Chip(
                          label: const Text('Revoked'),
                          backgroundColor: Colors.grey,
                          labelStyle: const TextStyle(color: Colors.white),
                          padding: EdgeInsets.zero,
                        )
                      else if (isExpired)
                        Chip(
                          label: const Text('Expired'),
                          backgroundColor: Colors.orange,
                          labelStyle: const TextStyle(color: Colors.white),
                          padding: EdgeInsets.zero,
                        )
                      else
                        Chip(
                          label: const Text('Active'),
                          backgroundColor: Colors.green,
                          labelStyle: const TextStyle(color: Colors.white),
                          padding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () =>
                          _copyToClipboard(codeText, 'Invite code'),
                      icon: const Icon(Icons.copy),
                      tooltip: 'Copy',
                    ),
                    IconButton(
                      onPressed: () => _shareInviteCode(code),
                      icon: const Icon(Icons.share),
                      tooltip: 'Share',
                    ),
                    if (isActive && !isExpired)
                      IconButton(
                        onPressed: () => _revokeCode(codeText),
                        icon: const Icon(Icons.block),
                        color: Colors.red,
                        tooltip: 'Revoke',
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildInfoChip(
                  Icons.people,
                  'Uses: $timesUsed${maxUses > 0 ? "/$maxUses" : " (unlimited)"}',
                ),
                if (restrictedEmail != null)
                  _buildInfoChip(Icons.email, restrictedEmail),
                if (restrictedRole != null)
                  _buildInfoChip(
                    Icons.badge,
                    _roleToDisplayName(
                      UserRole.fromApiValue(restrictedRole),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      labelStyle: const TextStyle(fontSize: 12),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  String _roleToDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.clinician:
        return 'Clinician';
      case UserRole.studyCoordinator:
        return 'Study Coordinator';
    }
  }
}
