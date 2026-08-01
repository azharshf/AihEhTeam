import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'main_layout.dart';
import 'doctor_login_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  void _signInPatient(BuildContext context, {bool isDemo = false}) async {
    if (!isDemo) {
      try {
        final AuthService auth = AuthService();
        final user = await auth.signInWithGoogle();
        if (user != null) {
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainLayout(role: 'Patient')),
            );
          }
          return;
        }
      } catch (e) {
        // Fall through to demo on failure
        debugPrint("Auth error: $e");
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sign-In failed or was cancelled. Continuing in Demo Mode.')),
        );
      }
    }
    
    // Fallback Demo Mode
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainLayout(role: 'Patient (Demo)')),
      );
    }
  }

  void _goToDoctorLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DoctorLoginScreen()),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Widget primaryAction,
    Widget? secondaryAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: bgColor.withOpacity(0.1), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: bgColor.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, size: 40, color: iconColor),
          ),
          const SizedBox(height: 24),
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          Text(description, style: const TextStyle(fontSize: 16, color: Color(0xFF64748B), height: 1.5)),
          const Spacer(),
          const SizedBox(height: 32),
          primaryAction,
          if (secondaryAction != null) ...[
            const SizedBox(height: 12),
            secondaryAction,
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10))],
                  ),
                  child: const Icon(Icons.favorite_rounded, size: 64, color: Color(0xFF3B82F6)),
                ),
                const SizedBox(height: 32),
                const Text('Welcome to LipidWise AI', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF0F172A), fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -1)),
                const SizedBox(height: 16),
                const Text('Next-Gen Preventive Dyslipidemia & ASCVD Risk Awareness System', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B), fontSize: 20, fontWeight: FontWeight.w500)),
                const SizedBox(height: 64),
                
                // Role Selection Grid
                LayoutBuilder(builder: (context, constraints) {
                  bool isWide = constraints.maxWidth > 800;

                  Widget patientCard = SizedBox(
                    height: isWide ? 420 : 380,
                    child: _buildRoleCard(
                      context: context,
                      title: 'General User / Patient',
                      description: 'Complete a quick health & lipid assessment, receive PREVENT™ 10-year risk calculation, personalized food swaps, and AI health report.',
                      icon: Icons.person_rounded,
                      iconColor: const Color(0xFF2563EB),
                      bgColor: const Color(0xFF3B82F6),
                      primaryAction: ElevatedButton.icon(
                        icon: const Icon(Icons.login, color: Colors.white, size: 20),
                        label: const Text('Sign in with Google', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () => _signInPatient(context),
                      ),
                      secondaryAction: OutlinedButton(
                        child: const Text('Continue as Guest', style: TextStyle(color: Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _signInPatient(context, isDemo: true),
                      )
                    ),
                  );

                  Widget doctorCard = SizedBox(
                    height: isWide ? 420 : 380,
                    child: _buildRoleCard(
                      context: context,
                      title: 'Healthcare Provider',
                      description: 'Access doctor portal, review patient risk list, inspect 2026 ACC/AHA guidelines summary, and add clinician follow-up notes.',
                      icon: Icons.medical_services_rounded,
                      iconColor: const Color(0xFF0F172A),
                      bgColor: const Color(0xFF94A3B8),
                      primaryAction: ElevatedButton.icon(
                        icon: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
                        label: const Text('Doctor Portal Login', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () => _goToDoctorLogin(context),
                      ),
                    ),
                  );

                  if (isWide) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: patientCard),
                        const SizedBox(width: 32),
                        Expanded(child: doctorCard),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      patientCard,
                      const SizedBox(height: 32),
                      doctorCard,
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
