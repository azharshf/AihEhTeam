import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'assessment_screen.dart';
import 'dashboard_screen.dart';
import 'landing_screen.dart';
import 'doctor_dashboard_screen.dart';

class MainLayout extends StatefulWidget {
  final String role;
  const MainLayout({super.key, required this.role});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _lastResult;
  final AuthService _auth = AuthService();

  void _onResultGenerated(Map<String, dynamic> result) {
    setState(() {
      _lastResult = result;
      _selectedIndex = 1; // Switch to Dashboard
    });
  }

  void _signOut() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LandingScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Sidebar
          NavigationRail(
            backgroundColor: Colors.white,
            extended: isDesktop,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563eb),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.favorite, color: Colors.white),
                  ),
                  if (isDesktop) const SizedBox(width: 12),
                  if (isDesktop) 
                    const Text(
                      'LipidWise AI', 
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))
                    ),
                ],
              ),
            ),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.grey),
                    onPressed: _signOut,
                    tooltip: 'Sign Out',
                  ),
                ),
              ),
            ),
            destinations: widget.role == 'Doctor' 
              ? const [
                  NavigationRailDestination(
                    icon: Icon(Icons.people_outline),
                    selectedIcon: Icon(Icons.people),
                    label: Text('All Patients'),
                  ),
                ]
              : const [
                  NavigationRailDestination(
                    icon: Icon(Icons.assignment_ind_outlined),
                    selectedIcon: Icon(Icons.assignment_ind),
                    label: Text('Patient Intake'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.pie_chart_outline),
                    selectedIcon: Icon(Icons.pie_chart),
                    label: Text('Risk Dashboard'),
                  ),
                ],
            selectedIconTheme: const IconThemeData(color: Color(0xFF2563eb)),
            selectedLabelTextStyle: const TextStyle(color: Color(0xFF2563eb), fontWeight: FontWeight.w600),
          ),
          
          const VerticalDivider(thickness: 1, width: 1, color: Color(0xFFE2E8F0)),
          
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.role == 'Doctor' 
                          ? 'Doctor Dashboard'
                          : (_selectedIndex == 0 ? 'Patient Intake Form' : 'Risk Dashboard'),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                      ),
                      Row(
                        children: [
                          Text('Logged in as: ${widget.role}', style: const TextStyle(color: Colors.grey)),
                          const SizedBox(width: 16),
                          CircleAvatar(
                            backgroundColor: const Color(0xFFDBEAFE),
                            child: Icon(Icons.person, color: const Color(0xFF2563eb)),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                
                // Disclaimer Banner
                if (widget.role != 'Doctor')
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFFFFBEB),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Safety Notice: This app does not diagnose disease or replace a doctor.',
                          style: TextStyle(color: Color(0xFF92400E), fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                
                // Dynamic Content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: widget.role == 'Doctor' 
                      ? DoctorDashboardScreen()
                      : (_selectedIndex == 0 
                          ? AssessmentScreen(role: widget.role, onResult: _onResultGenerated)
                          : (_lastResult == null 
                              ? const Center(child: Text('No patient data assessed yet. Go to Patient Intake.'))
                              : DashboardScreen(result: _lastResult!, role: widget.role))),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
