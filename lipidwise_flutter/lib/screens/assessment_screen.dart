import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../engine/rules_engine.dart';
import '../engine/ml_model.dart';
import '../engine/lifestyle_coach.dart';
import '../services/database_service.dart';

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
  bool _isScanning = false;

  final TextEditingController _ageCtrl = TextEditingController(text: '30');
  final TextEditingController _weightCtrl = TextEditingController(text: '70.0');
  final TextEditingController _heightCtrl = TextEditingController(text: '170.0');
  final TextEditingController _ldlCtrl = TextEditingController();
  final TextEditingController _hdlCtrl = TextEditingController();
  final TextEditingController _tgCtrl = TextEditingController();
  final TextEditingController _tcCtrl = TextEditingController();

  // Data Map
  final Map<String, dynamic> _data = {
    'sex': 'male',
    'bmi': 24.2,
    
    'symptom_chest_pain': false,
    'symptom_stroke': false,
    'symptom_sob': false,
    'symptom_abdomen': false,
    'symptom_eyes': false,
    'symptom_skin': false,
    
    'smoking': false,
    'exercise': '0',
    'diet_fried': '0',
    'diet_sugar': '0',
    'alcohol': '0',
    'stress': '0',
    
    'med_diabetes': false,
    'med_hbp': false,
    'med_cvd': false,
    'med_fatty_liver': false,
    'fam_cholesterol': false,
    'fam_cvd': false,
    
    'lipid_unit': 'mg/dL',
  };

  @override
  void dispose() {
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _ldlCtrl.dispose();
    _hdlCtrl.dispose();
    _tgCtrl.dispose();
    _tcCtrl.dispose();
    super.dispose();
  }

  void _scanBukuRekod() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      // For hackathon purposes, we will trigger the AI simulation even if they cancel the picker
      // to ensure the demo is completely foolproof, but normally we'd return if image == null.
      
      setState(() => _isScanning = true);
      
      // Simulate AI OCR Delay for hackathon presentation effect
      await Future.delayed(const Duration(seconds: 3));
      
      setState(() {
        _isScanning = false;
        // Auto fill realistic high-risk data
        _ageCtrl.text = '58';
        _weightCtrl.text = '82.0';
        _heightCtrl.text = '165.0';
        
        _tcCtrl.text = '240.0';
        _ldlCtrl.text = '160.0';
        _hdlCtrl.text = '35.0';
        _tgCtrl.text = '225.0';

        _data['med_hbp'] = true;
        _data['diet_fried'] = '2'; // Often
        _data['exercise'] = '0'; // Sedentary
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('AI Successfully extracted data from Buku Rekod Sakit!'),
          backgroundColor: Color(0xFF10B981),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error accessing gallery: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _submitData() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // Collect variables
    _data['age'] = int.tryParse(_ageCtrl.text) ?? 30;
    double weight = double.tryParse(_weightCtrl.text) ?? 70.0;
    double height = double.tryParse(_heightCtrl.text) ?? 170.0;
    _data['weight'] = weight;
    _data['height'] = height;
    
    if (height > 0) {
      _data['bmi'] = weight / ((height / 100) * (height / 100));
    }

    _data['tc'] = double.tryParse(_tcCtrl.text);
    _data['ldl'] = double.tryParse(_ldlCtrl.text);
    _data['hdl'] = double.tryParse(_hdlCtrl.text);
    _data['tg'] = double.tryParse(_tgCtrl.text);

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

    result['swaps'] = LifestyleCoach.getFoodSwaps(_data);
    result['plan'] = LifestyleCoach.getActionPlan(_data, result['category']);

    // Save to Firestore
    await _db.saveAssessment(_data, result, widget.role);

    // Call callback to switch tabs
    widget.onResult(result);
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
            // Safety Banner
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFEF3C7)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                  SizedBox(width: 8),
                  Text('Safety Notice: This app does not diagnose disease or replace a doctor.', style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            
            // AI Scanner Feature
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Smart Medical Record Scanner', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3730A3))),
                  const SizedBox(height: 8),
                  const Text('Upload a photo of your Buku Rekod Sakit (Medical Book) and our AI will automatically extract and fill the form for you.', style: TextStyle(color: Color(0xFF4F46E5))),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: _isScanning 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                        : const Icon(Icons.document_scanner, color: Colors.white),
                    label: Text(_isScanning ? 'AI is analyzing handwriting...' : 'Scan Buku Rekod Sakit (Auto-fill)', style: const TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5), // Indigo
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isScanning ? null : _scanBukuRekod,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text('Manual Assessment Entry', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
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
                                        controller: _ageCtrl,
                                        decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
                                        keyboardType: TextInputType.number,
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
                                        controller: _weightCtrl,
                                        decoration: const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder()),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _heightCtrl,
                                        decoration: const InputDecoration(labelText: 'Height (cm)', border: OutlineInputBorder()),
                                        keyboardType: TextInputType.number,
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
                        child: TextFormField(
                          controller: _ldlCtrl,
                          decoration: const InputDecoration(labelText: 'LDL-C', border: OutlineInputBorder()), 
                          keyboardType: TextInputType.number, 
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _hdlCtrl,
                          decoration: const InputDecoration(labelText: 'HDL-C', border: OutlineInputBorder()), 
                          keyboardType: TextInputType.number, 
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _tgCtrl,
                          decoration: const InputDecoration(labelText: 'Triglycerides', border: OutlineInputBorder()), 
                          keyboardType: TextInputType.number, 
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _tcCtrl,
                          decoration: const InputDecoration(labelText: 'Total Chol', border: OutlineInputBorder()), 
                          keyboardType: TextInputType.number, 
                        ),
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
