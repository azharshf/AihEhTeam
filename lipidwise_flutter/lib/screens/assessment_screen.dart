import 'package:flutter/material.dart';
import '../engine/rules_engine.dart';
import '../engine/ml_model.dart';
import '../engine/lifestyle_coach.dart';
import 'dashboard_screen.dart';

class AssessmentScreen extends StatefulWidget {
  final String role; // 'Patient' or 'Doctor'
  const AssessmentScreen({super.key, required this.role});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

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

  void _submitData() {
    bool hasEmergency = _data['symptom_chest_pain'] || _data['symptom_stroke'] || _data['symptom_sob'] || _data['symptom_abdomen'];
    bool hasLipids = _data['tc'] != null || _data['ldl'] != null || _data['hdl'] != null || _data['tg'] != null;
    
    Map<String, dynamic> result = {};

    if (hasEmergency) {
      result = {
        'category': 'Emergency',
        'message': 'Emergency warning: Your symptoms may be urgent. Please seek emergency medical care now.',
        'gaugeValue': 1.0,
        'typeBadge': 'Symptom Triage',
      };
    } else if (hasLipids) {
      var rulesRes = RulesEngine.analyzeLipids(
        tc: _data['tc'],
        ldl: _data['ldl'],
        hdl: _data['hdl'],
        tg: _data['tg'],
        unit: _data['lipid_unit'],
        sex: _data['sex'],
      );
      
      double gValue = 0.2;
      if (rulesRes['category'] == 'Moderate') gValue = 0.5;
      if (rulesRes['category'] == 'High') gValue = 0.8;
      if (rulesRes['category'] == 'Very High') gValue = 1.0;

      result = {
        ...rulesRes,
        'gaugeValue': gValue,
        'typeBadge': 'Clinical Rule-Based Analysis',
      };
    } else {
      var mlRes = MLPredictor.predictRisk(_data);
      result = {
        ...mlRes,
        'gaugeValue': mlRes['score'],
        'typeBadge': 'AI Machine Learning Prediction',
      };
    }

    // Add Coach Data
    result['swaps'] = LifestyleCoach.getFoodSwaps(_data);
    result['plan'] = LifestyleCoach.getActionPlan(_data, result['category']);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => DashboardScreen(result: result, role: widget.role)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assessment (${widget.role})'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 4) {
            setState(() => _currentStep += 1);
          } else {
            _submitData();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        steps: [
          Step(
            title: const Text('Emergency Symptoms'),
            content: Column(
              children: [
                CheckboxListTile(
                  title: const Text('Chest pain or discomfort', style: TextStyle(color: Colors.redAccent)),
                  value: _data['symptom_chest_pain'],
                  onChanged: (v) => setState(() => _data['symptom_chest_pain'] = v),
                ),
                CheckboxListTile(
                  title: const Text('Stroke-like symptoms (face drooping, arm weakness)', style: TextStyle(color: Colors.redAccent)),
                  value: _data['symptom_stroke'],
                  onChanged: (v) => setState(() => _data['symptom_stroke'] = v),
                ),
                CheckboxListTile(
                  title: const Text('Severe shortness of breath', style: TextStyle(color: Colors.redAccent)),
                  value: _data['symptom_sob'],
                  onChanged: (v) => setState(() => _data['symptom_sob'] = v),
                ),
                CheckboxListTile(
                  title: const Text('Yellowish patches around eyelids (Xanthelasma)'),
                  value: _data['symptom_eyes'],
                  onChanged: (v) => setState(() => _data['symptom_eyes'] = v),
                ),
              ],
            ),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('Body Profile'),
            content: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _data['age'] = int.tryParse(v) ?? 30,
                ),
                DropdownButtonFormField<String>(
                  value: _data['sex'],
                  decoration: const InputDecoration(labelText: 'Biological Sex'),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                  ],
                  onChanged: (v) => setState(() => _data['sex'] = v),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Height (cm)'),
                  keyboardType: TextInputType.number,
                  initialValue: _data['height'].toString(),
                  onChanged: (v) { _data['height'] = double.tryParse(v) ?? 170.0; _calculateBMI(); },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Weight (kg)'),
                  keyboardType: TextInputType.number,
                  initialValue: _data['weight'].toString(),
                  onChanged: (v) { _data['weight'] = double.tryParse(v) ?? 70.0; _calculateBMI(); },
                ),
                const SizedBox(height: 10),
                Text('Estimated BMI: ${_data['bmi'].toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              ],
            ),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: const Text('Lifestyle & Habits'),
            content: Column(
              children: [
                SwitchListTile(
                  title: const Text('Current Smoker / Vaping'),
                  value: _data['smoking'],
                  onChanged: (v) => setState(() => _data['smoking'] = v),
                ),
                DropdownButtonFormField<String>(
                  value: _data['diet_fried'],
                  decoration: const InputDecoration(labelText: 'Fried Food Intake'),
                  items: const [
                    DropdownMenuItem(value: '0', child: Text('Rarely (0-1 / week)')),
                    DropdownMenuItem(value: '1', child: Text('Sometimes (2-3 / week)')),
                    DropdownMenuItem(value: '2', child: Text('Often (4+ / week)')),
                  ],
                  onChanged: (v) => setState(() => _data['diet_fried'] = v),
                ),
                DropdownButtonFormField<String>(
                  value: _data['diet_sugar'],
                  decoration: const InputDecoration(labelText: 'Sugary Drinks'),
                  items: const [
                    DropdownMenuItem(value: '0', child: Text('Rarely')),
                    DropdownMenuItem(value: '1', child: Text('Sometimes')),
                    DropdownMenuItem(value: '2', child: Text('Daily')),
                  ],
                  onChanged: (v) => setState(() => _data['diet_sugar'] = v),
                ),
                DropdownButtonFormField<String>(
                  value: _data['exercise'],
                  decoration: const InputDecoration(labelText: 'Physical Activity'),
                  items: const [
                    DropdownMenuItem(value: '0', child: Text('Sedentary')),
                    DropdownMenuItem(value: '1', child: Text('Light (1-2 days)')),
                    DropdownMenuItem(value: '2', child: Text('Moderate (3-4 days)')),
                    DropdownMenuItem(value: '3', child: Text('Active (5+ days)')),
                  ],
                  onChanged: (v) => setState(() => _data['exercise'] = v),
                ),
                DropdownButtonFormField<String>(
                  value: _data['stress'],
                  decoration: const InputDecoration(labelText: 'Chronic Stress'),
                  items: const [
                    DropdownMenuItem(value: '0', child: Text('Low')),
                    DropdownMenuItem(value: '1', child: Text('Moderate')),
                    DropdownMenuItem(value: '2', child: Text('High')),
                  ],
                  onChanged: (v) => setState(() => _data['stress'] = v),
                ),
              ],
            ),
            isActive: _currentStep >= 2,
          ),
          Step(
            title: const Text('Medical History'),
            content: Column(
              children: [
                CheckboxListTile(
                  title: const Text('Diabetes / High Blood Sugar'),
                  value: _data['med_diabetes'],
                  onChanged: (v) => setState(() => _data['med_diabetes'] = v),
                ),
                CheckboxListTile(
                  title: const Text('High Blood Pressure'),
                  value: _data['med_hbp'],
                  onChanged: (v) => setState(() => _data['med_hbp'] = v),
                ),
                CheckboxListTile(
                  title: const Text('Family History of High Cholesterol'),
                  value: _data['fam_cholesterol'],
                  onChanged: (v) => setState(() => _data['fam_cholesterol'] = v),
                ),
              ],
            ),
            isActive: _currentStep >= 3,
          ),
          Step(
            title: const Text('Lipid Profile (Optional)'),
            content: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _data['lipid_unit'],
                  decoration: const InputDecoration(labelText: 'Preferred Unit'),
                  items: const [
                    DropdownMenuItem(value: 'mg/dL', child: Text('mg/dL')),
                    DropdownMenuItem(value: 'mmol/L', child: Text('mmol/L')),
                  ],
                  onChanged: (v) => setState(() => _data['lipid_unit'] = v),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Total Cholesterol'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _data['tc'] = double.tryParse(v),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'LDL-C (Bad)'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _data['ldl'] = double.tryParse(v),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'HDL-C (Good)'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _data['hdl'] = double.tryParse(v),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Triglycerides'),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _data['tg'] = double.tryParse(v),
                ),
              ],
            ),
            isActive: _currentStep >= 4,
          ),
        ],
      ),
    );
  }
}
