import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../engine/rules_engine.dart';
import '../engine/ml_model.dart';
import '../engine/lifestyle_coach.dart';
import '../services/database_service.dart';
import '../services/chat_service.dart';

class AssessmentScreen extends StatefulWidget {
  final String role;
  final Function(Map<String, dynamic>) onResult;
  const AssessmentScreen({super.key, required this.role, required this.onResult});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _db = DatabaseService();
  final ChatService _chat = ChatService();

  // Data Map
  final Map<String, dynamic> _data = {
    'age': 30,
    'sex': 'male',
    'height': 170.0,
    'weight': 70.0,
    'bmi': 24.2,
    
    // Symptoms
    'symptom_chest_pain': false,
    'symptom_stroke': false,
    'symptom_sob': false,
    'symptom_abdomen': false,
    'symptom_eyes': false,
    'symptom_skin': false,
    
    // Lifestyle
    'smoking': false,
    'exercise': '0',
    'diet_fried': '0',
    'diet_sugar': '0',
    'alcohol': '0',
    'stress': '0',
    
    // Medical
    'med_diabetes': false,
    'med_hbp': false,
    'med_cvd': false,
    'med_fatty_liver': false,
    'fam_cholesterol': false,
    'fam_cvd': false,
    
    // Lipids
    'lipid_unit': 'mg/dL',
    'tc': null,
    'ldl': null,
    'hdl': null,
    'tg': null,
  };

  void _calculateBMI() {
    double h = _data['height'] / 100;
    double w = _data['weight'];
    if (h > 0) {
      setState(() {
        _data['bmi'] = w / (h * h);
      });
    }
  }

  void _submitData() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    bool hasEmergency = _data['symptom_chest_pain'] || _data['symptom_stroke'] || _data['symptom_sob'] || _data['symptom_abdomen'];
    bool hasLipids = _data['tc'] != null && _data['ldl'] != null && _data['hdl'] != null && _data['tg'] != null;
    
    Map<String, dynamic> result = {};

    if (hasEmergency) {
      result = {
        'category': 'Emergency',
        'message': 'Emergency warning: Your symptoms may be urgent. Please seek emergency medical care now.',
        'gaugeValue': 1.0,
        'typeBadge': 'Symptom Triage',
      };
    } else {
      var rulesRes = RulesEngine.analyzeLipids(
        tc: _data['tc'],
        ldl: _data['ldl'],
        hdl: _data['hdl'],
        tg: _data['tg'],
        lpa: _data['lpa'],
        lpaUnit: _data['lpa_unit'] ?? 'nmol/L',
        unit: _data['lipid_unit'],
        sex: _data['sex'],
        age: (_data['age'] as num?)?.toInt() ?? 45,
        sysBp: (_data['sys_bp'] as num?)?.toDouble(),
        smoking: _data['smoking'] == true || _data['smoking'] == '1',
        diabetes: _data['med_diabetes'] == true,
        hasASCVD: _data['med_cvd'] == true || _data['symptom_stroke'] == true,
      );
      
      double gValue = 0.2;
      if (rulesRes['category'] == 'Moderate') gValue = 0.5;
      if (rulesRes['category'] == 'High') gValue = 0.8;
      if (rulesRes['category'] == 'Very High') gValue = 1.0;

      result = {
        ...rulesRes,
        'gaugeValue': gValue,
        'typeBadge': '2026 ACC/AHA Rule-Based Analysis',
      };
    }

    result['swaps'] = LifestyleCoach.getFoodSwaps(_data);
    result['plan'] = LifestyleCoach.getActionPlan(_data, result['category']);

    // Save to Firestore
    await _db.saveAssessment(_data, result, widget.role);

    // Sync to LipidWise AI chatbot backend so it has patient context
    final sessionId = FirebaseAuth.instance.currentUser?.uid;
    if (sessionId != null) {
      try {
        await _chat.syncPatientProfile(sessionId: sessionId, profile: _toChatProfile());
      } catch (_) {
        // Chatbot backend may be offline — assessment flow should not block on it.
      }
    }

    // Call callback to switch tabs
    widget.onResult(result);
  }

  /// Maps the intake form's internal field names to the chatbot backend's
  /// PatientProfileRequest schema (lipidwise-chatbot/main.py).
  Map<String, dynamic> _toChatProfile() {
    return {
      'age': _data['age'],
      'sex': _data['sex'],
      'weight_kg': _data['weight'],
      'height_cm': _data['height'],
      'ldl_c': _data['ldl'],
      'hdl_c': _data['hdl'],
      'triglycerides': _data['tg'],
      'total_cholesterol': _data['tc'],
      'smoker': _data['smoking'] == true || _data['smoking'] == '1',
      'exercise_mins_per_week': _exerciseMinsFromLevel(_data['exercise']),
      'has_diabetes': _data['med_diabetes'] == true,
      'has_hypertension': _data['med_hbp'] == true,
      'has_family_history_heart': _data['fam_cvd'] == true,
      'has_family_history_cholesterol': _data['fam_cholesterol'] == true,
    }..removeWhere((key, value) => value == null);
  }

  int? _exerciseMinsFromLevel(dynamic level) {
    switch (level) {
      case '0':
        return 0;
      case '1':
        return 90; // Light: 1-2 days/week, ~45min each
      case '2':
        return 210; // Moderate: 3-4 days/week
      case '3':
        return 300; // Active: 5+ days/week
      default:
        return null;
    }
  }

  Widget _buildCard(String title, IconData icon, Widget child, {Color? color, Color? iconColor}) {
    return Card(
      color: color ?? Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color != null ? color.withOpacity(0.5) : const Color(0xFFF1F5F9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor ?? const Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('New Assessment', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            const Text('Enter patient health, lifestyle, and clinical data to generate an AI prevention plan.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),

            LayoutBuilder(
              builder: (context, constraints) {
                bool isWide = constraints.maxWidth > 800;
                
                return Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: isWide ? 1 : 0,
                      child: Column(
                        children: [
                          _buildCard(
                            'Basic Data', Icons.badge_outlined,
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) => _data['age'] = int.tryParse(v) ?? 30,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: _data['sex'],
                                        decoration: const InputDecoration(labelText: 'Sex', border: OutlineInputBorder()),
                                        items: const [
                                          DropdownMenuItem(value: 'male', child: Text('Male')),
                                          DropdownMenuItem(value: 'female', child: Text('Female')),
                                        ],
                                        onChanged: (v) => setState(() => _data['sex'] = v),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        decoration: const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder()),
                                        keyboardType: TextInputType.number,
                                        initialValue: _data['weight'].toString(),
                                        onChanged: (v) { _data['weight'] = double.tryParse(v) ?? 70.0; _calculateBMI(); },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        decoration: const InputDecoration(labelText: 'Height (cm)', border: OutlineInputBorder()),
                                        keyboardType: TextInputType.number,
                                        initialValue: _data['height'].toString(),
                                        onChanged: (v) { _data['height'] = double.tryParse(v) ?? 170.0; _calculateBMI(); },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildCard(
                            'Medical History', Icons.medical_services_outlined,
                            Column(
                              children: [
                                SwitchListTile(title: const Text('Diabetes'), value: _data['med_diabetes'], onChanged: (v) => setState(() => _data['med_diabetes'] = v)),
                                SwitchListTile(title: const Text('High Blood Pressure'), value: _data['med_hbp'], onChanged: (v) => setState(() => _data['med_hbp'] = v)),
                                SwitchListTile(title: const Text('Family History (Early CVD)'), value: _data['fam_cvd'], onChanged: (v) => setState(() => _data['fam_cvd'] = v)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isWide) const SizedBox(width: 24),
                    Expanded(
                      flex: isWide ? 1 : 0,
                      child: Column(
                        children: [
                          _buildCard(
                            'Lifestyle Habits', Icons.directions_run,
                            Column(
                              children: [
                                SwitchListTile(title: const Text('Current Smoker'), value: _data['smoking'], onChanged: (v) => setState(() => _data['smoking'] = v)),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _data['diet_fried'],
                                  decoration: const InputDecoration(labelText: 'Fried Food Intake', border: OutlineInputBorder()),
                                  items: const [
                                    DropdownMenuItem(value: '0', child: Text('Rarely (0-1 / week)')),
                                    DropdownMenuItem(value: '1', child: Text('Sometimes (2-3 / week)')),
                                    DropdownMenuItem(value: '2', child: Text('Often (4+ / week)')),
                                  ],
                                  onChanged: (v) => setState(() => _data['diet_fried'] = v),
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _data['exercise'],
                                  decoration: const InputDecoration(labelText: 'Physical Activity', border: OutlineInputBorder()),
                                  items: const [
                                    DropdownMenuItem(value: '0', child: Text('Sedentary')),
                                    DropdownMenuItem(value: '1', child: Text('Light')),
                                    DropdownMenuItem(value: '2', child: Text('Moderate')),
                                    DropdownMenuItem(value: '3', child: Text('Active')),
                                  ],
                                  onChanged: (v) => setState(() => _data['exercise'] = v),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildCard(
                            'Emergency Symptoms', Icons.warning_amber_rounded,
                            color: const Color(0xFFFEF2F2),
                            iconColor: const Color(0xFFDC2626),
                            Column(
                              children: [
                                const Text('Check any that apply immediately.', style: TextStyle(color: Color(0xFFDC2626), fontSize: 12)),
                                const SizedBox(height: 12),
                                CheckboxListTile(title: const Text('Chest Pain'), value: _data['symptom_chest_pain'], onChanged: (v) => setState(() => _data['symptom_chest_pain'] = v), activeColor: const Color(0xFFDC2626)),
                                CheckboxListTile(title: const Text('Shortness of Breath'), value: _data['symptom_sob'], onChanged: (v) => setState(() => _data['symptom_sob'] = v), activeColor: const Color(0xFFDC2626)),
                                CheckboxListTile(title: const Text('Stroke-like signs'), value: _data['symptom_stroke'], onChanged: (v) => setState(() => _data['symptom_stroke'] = v), activeColor: const Color(0xFFDC2626)),
                              ],
                            )
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
            ),

            const SizedBox(height: 24),
            _buildCard(
              'Lipid Profile', Icons.science_outlined,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Optional. Leave blank to trigger ML Risk Prediction mode.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(decoration: const InputDecoration(labelText: 'LDL-C', border: OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => _data['ldl'] = double.tryParse(v)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(decoration: const InputDecoration(labelText: 'HDL-C', border: OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => _data['hdl'] = double.tryParse(v)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(decoration: const InputDecoration(labelText: 'Triglycerides', border: OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => _data['tg'] = double.tryParse(v)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(decoration: const InputDecoration(labelText: 'Total Chol', border: OutlineInputBorder()), keyboardType: TextInputType.number, onChanged: (v) => _data['tc'] = double.tryParse(v)),
                      ),
                    ],
                  ),
                ],
              )
            ),

            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                label: const Text('Generate AI Analysis', style: TextStyle(color: Colors.white, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _submitData,
              ),
            ),
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }
}
