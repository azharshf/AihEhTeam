import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../widgets/animated_entrance.dart';
import '../widgets/fade_slide_page_route.dart';
import 'dashboard_screen.dart';

class DoctorDashboardScreen extends StatelessWidget {
  DoctorDashboardScreen({super.key});
  final DatabaseService _db = DatabaseService();

  Color _getRiskColor(String category) {
    if (category.contains('Emergency') || category.contains('High')) return const Color(0xFFDC2626);
    if (category.contains('Moderate')) return const Color(0xFFD97706);
    return const Color(0xFF10B981);
  }

  void _viewPatient(BuildContext context, Map<String, dynamic> resultData) {
    Navigator.push(
      context,
      FadeSlidePageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Patient Detailed Report')),
          body: DashboardScreen(result: resultData, role: 'Doctor'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.getAssessmentsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error loading data.'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('No patient assessments found in the database.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('All Patient Assessments', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                Text('Real-time feed of patient data syncing from Firebase.', style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 24),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final aiResult = data['aiResult'] as Map<String, dynamic>? ?? {};
                      final inputData = data['inputData'] as Map<String, dynamic>? ?? {};
                      
                      final date = data['timestamp'] != null 
                          ? DateFormat('MMM d, yyyy - HH:mm').format((data['timestamp'] as Timestamp).toDate()) 
                          : 'Just now';
                      
                      final category = aiResult['category'] ?? 'Unknown';
                      final color = _getRiskColor(category);

                      return AnimatedEntrance(
                        delay: Duration(milliseconds: 40 * index.clamp(0, 12)),
                        beginOffset: const Offset(0.03, 0),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: color.withOpacity(0.1),
                            child: Icon(Icons.person, color: color),
                          ),
                          title: Row(
                            children: [
                              Text(data['userEmail'] ?? 'Unknown Patient', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                child: Text(category, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('Age: ${inputData['age']} | Sex: ${inputData['sex']} | BMI: ${inputData['bmi']?.toStringAsFixed(1)} \nAssessed: $date'),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _viewPatient(context, aiResult),
                            child: const Text('View Report'),
                          ),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          );
        }
      ),
    );
  }
}
