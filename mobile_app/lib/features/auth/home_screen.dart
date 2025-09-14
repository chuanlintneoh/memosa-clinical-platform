import 'package:flutter/material.dart';
import 'package:mobile_app/features/roles/screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  final String email;
  final String role;
  final String name;
  const HomeScreen({
    super.key,
    required this.userId,
    required this.email,
    required this.role,
    required this.name,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isExpanded = false;

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, "/", (_) => false);
    }
  }

  List<Widget> _buildMenuItems() {
    switch (widget.role) {
      case "study_coordinator":
        return [
          _buildNavButton(Icons.drafts, "Draft Cases"),
          _buildNavButton(Icons.edit, "Edit Case"),
        ];
      case "clinician":
        return [_buildNavButton(Icons.search, "Undiagnosed Cases")];
      case "admin":
        return [_buildNavButton(Icons.file_download, "Export Bundle")];
      default:
        return [const Text("Unknown role")];
    }
  }

  Widget _buildNavButton(IconData icon, String label) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: _isExpanded
          ? Text(label, style: const TextStyle(color: Colors.white))
          : null,
      onTap: () {
        switch (label) {
          case "Draft Cases":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DraftCasesScreen()),
            );
            break;
          case "Edit Case":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditCaseScreen()),
            );
            break;
          case "Undiagnosed Cases":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UndiagnosedCasesScreen()),
            );
            break;
          case "Export Bundle":
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExportBundleScreen()),
            );
            break;
          default:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PageNotFoundScreen()),
            );
            break;
        }
      },
    );
  }

  List<Widget> _buildQuickActions() {
    switch (widget.role) {
      case "study_coordinator":
        return [
          _buildQuickAction(Icons.drafts, "Draft & Create Cases", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DraftCasesScreen()),
            );
          }),
          _buildQuickAction(Icons.edit, "Search & Edit Case", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditCaseScreen()),
            );
          }),
        ];
      case "clinician":
        return [
          _buildQuickAction(Icons.search, "Undiagnosed Cases", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UndiagnosedCasesScreen()),
            );
          }),
        ];
      case "admin":
        return [
          _buildQuickAction(Icons.file_download, "Export Bundle", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ExportBundleScreen()),
            );
          }),
        ];
      default:
        return [];
    }
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blueGrey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blueGrey.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: Colors.blueGrey[800]),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            AnimatedContainer(
              duration: _isExpanded
                  ? const Duration(milliseconds: 10)
                  : const Duration(milliseconds: 100),
              width: _isExpanded ? 200 : 70,
              color: Colors.blueGrey[900],
              child: Column(
                crossAxisAlignment: _isExpanded
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: CircleAvatar(radius: 24, child: Icon(Icons.person)),
                  ),
                  if (_isExpanded) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        widget.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Center(
                      child: Text(
                        widget.role,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    Center(
                      child: Text(
                        widget.email,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 60),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ListView(
                        shrinkWrap: true,
                        children: _buildMenuItems(),
                      ),
                    ),
                  ),
                  _isExpanded
                      ? ListTile(
                          leading: Icon(Icons.logout, color: Colors.white),
                          title: Text(
                            "Logout",
                            style: TextStyle(color: Colors.white),
                          ),
                          onTap: _logout,
                        )
                      : IconButton(
                          icon: Icon(Icons.logout, color: Colors.white),
                          onPressed: _logout,
                        ),

                  Align(
                    alignment: _isExpanded
                        ? Alignment.centerRight
                        : Alignment.center,
                    child: IconButton(
                      icon: Icon(
                        _isExpanded
                            ? Icons.arrow_back_ios
                            : Icons.arrow_forward_ios,
                        color: Colors.white,
                      ),
                      onPressed: () =>
                          setState(() => _isExpanded = !_isExpanded),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AspectRatio(
                          aspectRatio: 3,
                          child: Image.asset('assets/images/logo_crmy.webp'),
                        ),
                        const SizedBox(height: 20),

                        Card(
                          elevation: _isExpanded ? 50 : 100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "👋 Welcome to MeMoSA\nClinical Platform,\n${widget.name}.",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (!_isExpanded) ...[
                                  Text(
                                    "Role: ${widget.role}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  Text(
                                    "Email:\n${widget.email}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 50),

                        Text(
                          "Quick Actions",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: _buildQuickActions()
                              .map(
                                (action) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: action,
                                  ),
                                ),
                              )
                              .toList(),
                        ),

                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
