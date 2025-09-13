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
  bool _isExpanded = true;

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
        return [_buildNavButton(Icons.file_download, "Export Mastersheet")];
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
          case "Export Mastersheet":
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ExportMastersheetScreen(),
              ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // Sidebar
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

            // Main Content Area
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        "Welcome ${widget.name}! You are logged in as role: ${widget.role}.",
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
