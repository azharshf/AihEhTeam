import 'package:flutter/material.dart';
import 'assessment_screen.dart';
import 'dashboard_screen.dart';
import 'doctor_dashboard_screen.dart';
import 'settings_screen.dart';

class MainLayout extends StatefulWidget {
  final String role;
  const MainLayout({super.key, required this.role});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _lastResult;

  void _onResultGenerated(Map<String, dynamic> result) {
    setState(() {
      _lastResult = result;
      _selectedIndex = 1; // Switch to Dashboard view
    });
  }

  Widget _buildDynamicContent() {
    if (widget.role == 'Doctor') {
      if (_selectedIndex == 0) return DoctorDashboardScreen();
      return SettingsScreen(role: widget.role);
    } else {
      if (_selectedIndex == 0) return AssessmentScreen(role: widget.role, onResult: _onResultGenerated);
      if (_selectedIndex == 1) {
        return _lastResult == null 
            ? const Center(child: Text('No patient data assessed yet. Go to Patient Intake.'))
            : DashboardScreen(result: _lastResult!, role: widget.role);
      }
      return SettingsScreen(role: widget.role);
    }
  }

  String _getTitle() {
    if (widget.role == 'Doctor') {
      return _selectedIndex == 0 ? 'Doctor Dashboard' : 'Settings';
    }
    if (_selectedIndex == 0) return 'Patient Intake Form';
    if (_selectedIndex == 1) return 'Risk Dashboard';
    return 'Settings';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;

    final List<NavigationDestination> mobileDestinations = widget.role == 'Doctor'
        ? const [
            NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Patients'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
          ]
        : const [
            NavigationDestination(icon: Icon(Icons.assignment_ind_outlined), selectedIcon: Icon(Icons.assignment_ind), label: 'Intake'),
            NavigationDestination(icon: Icon(Icons.pie_chart_outline), selectedIcon: Icon(Icons.pie_chart), label: 'Dashboard'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
          ];

    final List<NavigationRailDestination> desktopDestinations = widget.role == 'Doctor'
        ? const [
            NavigationRailDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: Text('All Patients')),
            NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
          ]
        : const [
            NavigationRailDestination(icon: Icon(Icons.assignment_ind_outlined), selectedIcon: Icon(Icons.assignment_ind), label: Text('Patient Intake')),
            NavigationRailDestination(icon: Icon(Icons.pie_chart_outline), selectedIcon: Icon(Icons.pie_chart), label: Text('Risk Dashboard')),
            NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
          ];

    Widget mainContentArea = Column(
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
              Text(_getTitle(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
              if (isDesktop)
                Row(
                  children: [
                    Text('Logged in as: ${widget.role}', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(width: 16),
                    CircleAvatar(backgroundColor: const Color(0xFFDBEAFE), child: Icon(Icons.person, color: const Color(0xFF2563eb)))
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
                Flexible(
                  child: Text(
                    'Safety Notice: This app does not diagnose disease or replace a doctor.',
                    style: TextStyle(color: Color(0xFF92400E), fontSize: 13, fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        
        // Dynamic Content
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildDynamicContent(),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: isDesktop
        ? Row(
            children: [
              NavigationRail(
                backgroundColor: Colors.white,
                extended: true,
                selectedIndex: _selectedIndex,
                onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFF2563eb), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.favorite, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Text('LipidWise AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A))),
                    ],
                  ),
                ),
                destinations: desktopDestinations,
                selectedIconTheme: const IconThemeData(color: Color(0xFF2563eb)),
                selectedLabelTextStyle: const TextStyle(color: Color(0xFF2563eb), fontWeight: FontWeight.w600),
              ),
              const VerticalDivider(thickness: 1, width: 1, color: Color(0xFFE2E8F0)),
              Expanded(child: mainContentArea),
            ],
          )
        : mainContentArea,
      bottomNavigationBar: !isDesktop 
        ? NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
            destinations: mobileDestinations,
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFFDBEAFE),
          )
        : null,
    );
  }
}
