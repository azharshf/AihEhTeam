import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'landing_screen.dart';

class SettingsScreen extends StatelessWidget {
  final String role;
  const SettingsScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final user = auth.currentUser;

    void _signOut() async {
      await auth.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LandingScreen()),
          (Route<dynamic> route) => false,
        );
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Account Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 24),
          
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE2E8F0))),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFFEFF6FF),
                    child: Icon(Icons.person, size: 40, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(height: 16),
                  Text(user?.email ?? 'Unknown User', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                    child: Text('Role: $role', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
                      label: const Text('Log Out Safely', style: TextStyle(color: Color(0xFFEF4444), fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEF2F2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _signOut,
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
