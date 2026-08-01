import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'main_layout.dart';
import 'doctor_login_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  void _signInPatient(BuildContext context) async {
    final AuthService auth = AuthService();
    final user = await auth.signInWithGoogle();
    if (user != null) {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainLayout(role: 'Patient')),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to sign in via Google. Make sure it is enabled in Firebase Console.')));
      }
    }
  }

  void _goToDoctorLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DoctorLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite, size: 80, color: Color(0xFF3B82F6)),
              const SizedBox(height: 24),
              const Text('Welcome to LipidWise AI', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Select your role to continue', style: TextStyle(color: Colors.white70, fontSize: 18)),
              const SizedBox(height: 48),
              
              ElevatedButton.icon(
                icon: const Icon(Icons.person, color: Colors.white),
                label: const Text('Sign in as Patient (Google)', style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _signInPatient(context),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.medical_services, color: Color(0xFF0F172A)),
                label: const Text('Doctor Portal Login', style: TextStyle(color: Color(0xFF0F172A), fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _goToDoctorLogin(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
