import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../engine/rules_engine.dart';
import '../engine/ml_model.dart';
import '../engine/lifestyle_coach.dart';
import '../engine/lab_report_parser.dart';
import '../services/database_service.dart';
import '../services/ocr_service.dart';
import '../widgets/animated_entrance.dart';

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
  Uint8List? _capturedImageBytes;
  String? _capturedImageName;

  // Real OCR state — populated only from what Tesseract.js actually reads
  // off the image. No field here is ever pre-filled with canned data.
  Map<String, dynamic> _extractedFields = {};
  String? _lastOcrText;
  String? _ocrError;
  bool _showRawText = false;

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

  Future<ImageSource?> _showSourceDialog() {
    return showGeneralDialog<ImageSource>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Select image source',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (ctx, anim, secAnim) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 40, offset: const Offset(0, 20)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.document_scanner_rounded, color: Color(0xFF4F46E5)),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text('Select Image Source', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose how you want to capture the Buku Rekod Sakit page.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(builder: (context, constraints) {
                      bool isWide = constraints.maxWidth > 420;
                      return Flex(
                        direction: isWide ? Axis.horizontal : Axis.vertical,
                        children: [
                          Expanded(
                            child: _SourceOptionCard(
                              icon: Icons.camera_alt_rounded,
                              iconColor: const Color(0xFF4F46E5),
                              accent: const Color(0xFF4F46E5),
                              title: 'Open Camera',
                              subtitle: 'Take a live photo with your webcam',
                              onTap: () => Navigator.pop(ctx, ImageSource.camera),
                            ),
                          ),
                          SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 16),
                          Expanded(
                            child: _SourceOptionCard(
                              icon: Icons.folder_open_rounded,
                              iconColor: const Color(0xFF059669),
                              accent: const Color(0xFF059669),
                              title: 'Choose from Desktop',
                              subtitle: 'Select an image file from your computer',
                              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                            ),
                          ),
                        ],
                      );
                    }),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curved),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  void _applyExtractedFields(Map<String, dynamic> extracted) {
    if (extracted['age'] != null) _ageCtrl.text = extracted['age'].toString();
    if (extracted['weight'] != null) _weightCtrl.text = extracted['weight'].toString();
    if (extracted['height'] != null) _heightCtrl.text = extracted['height'].toString();
    if (extracted['tc'] != null) _tcCtrl.text = extracted['tc'].toString();
    if (extracted['ldl'] != null) _ldlCtrl.text = extracted['ldl'].toString();
    if (extracted['hdl'] != null) _hdlCtrl.text = extracted['hdl'].toString();
    if (extracted['tg'] != null) _tgCtrl.text = extracted['tg'].toString();
    if (extracted['med_hbp'] != null) _data['med_hbp'] = extracted['med_hbp'];
    if (extracted['med_diabetes'] != null) _data['med_diabetes'] = extracted['med_diabetes'];
    if (extracted['smoking'] != null) _data['smoking'] = extracted['smoking'];
  }

  Future<void> _scanBukuRekod() async {
    final ImageSource? source = await _showSourceDialog();
    if (source == null) return; // User cancelled

    XFile? pickedFile;
    try {
      final ImagePicker picker = ImagePicker();
      pickedFile = await picker.pickImage(source: source, imageQuality: 90);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not open ${source == ImageSource.camera ? 'the camera' : 'the file picker'}: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ));
      }
      return;
    }

    if (pickedFile == null) return; // User cancelled the picker itself

    final bytes = await pickedFile.readAsBytes();
    final mimeType = pickedFile.mimeType ?? 'image/jpeg';

    setState(() {
      _capturedImageBytes = bytes;
      _capturedImageName = pickedFile!.name;
      _isScanning = true;
      _extractedFields = {};
      _lastOcrText = null;
      _ocrError = null;
      _showRawText = false;
    });

    // Real OCR: this actually decodes the image and reads its pixels via
    // Tesseract.js (web) — see lib/services/ocr_service_web.dart.
    final result = await OcrService.recognizeText(bytes, mimeType: mimeType);

    if (!mounted) return;

    if (!result.success) {
      setState(() {
        _isScanning = false;
        _ocrError = result.error ?? 'OCR failed for an unknown reason.';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('⚠️ ${_ocrError!}'),
        backgroundColor: const Color(0xFFDC2626),
      ));
      return;
    }

    final extracted = LabReportParser.parse(result.rawText);

    setState(() {
      _isScanning = false;
      _lastOcrText = result.rawText;
      _extractedFields = extracted;
      _applyExtractedFields(extracted);
    });

    if (mounted) {
      final count = extracted.length;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(count > 0
            ? '✅ AI extracted $count field${count == 1 ? '' : 's'} from the document.'
            : 'ℹ️ Scan complete, but no recognizable lab values were found. Check the raw text below or fill in manually.'),
        backgroundColor: count > 0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
      ));
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

  Widget _extractedChip(String label, String value) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Transform.scale(scale: v.clamp(0.0, 1.0), child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF6EE7B7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label: ', style: const TextStyle(color: Color(0xFF065F46), fontSize: 12, fontWeight: FontWeight.w500)),
            Text(value, style: const TextStyle(color: Color(0xFF059669), fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerCard() {
    return Container(
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
          Text(
            OcrService.isSupported
                ? 'Take a photo with your camera or select a file from your desktop. Our on-device OCR AI will read the page and fill the form for you.'
                : 'Take a photo with your camera or select a file from your desktop. (Live OCR text-recognition currently runs only in the web build.)',
            style: const TextStyle(color: Color(0xFF4F46E5)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                icon: _isScanning
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.document_scanner, color: Colors.white),
                label: Text(_isScanning ? 'AI is reading the document...' : 'Scan Buku Rekod Sakit (Auto-fill)', style: const TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isScanning ? null : _scanBukuRekod,
              ),
              if (_capturedImageName != null) ...[
                const SizedBox(width: 16),
                Chip(
                  avatar: const Icon(Icons.check_circle, color: Color(0xFF059669), size: 18),
                  label: Text(_capturedImageName!, style: const TextStyle(fontSize: 12)),
                  backgroundColor: const Color(0xFFECFDF5),
                ),
              ],
            ],
          ),
          // Image Preview
          if (_capturedImageBytes != null) ...[
            const SizedBox(height: 20),
            const Text('📄 Captured Document Preview:', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF3730A3))),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Image.memory(
                    _capturedImageBytes!,
                    width: double.infinity,
                    height: 280,
                    fit: BoxFit.cover,
                  ),
                  if (_isScanning)
                    const Positioned.fill(child: _ScanningOverlay()),
                ],
              ),
            ),
          ],
          // OCR failure / no-data state — honest, not silently swapped for fake data.
          if (_capturedImageBytes != null && !_isScanning && _ocrError != null) ...[
            const SizedBox(height: 16),
            AnimatedEntrance(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(_ocrError!, style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          ],
          // Extracted Data Confirmation
          if (_capturedImageBytes != null && !_isScanning && _ocrError == null) ...[
            const SizedBox(height: 16),
            AnimatedEntrance(
              beginOffset: const Offset(0, 0.15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF6EE7B7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF059669)),
                        const SizedBox(width: 8),
                        Text(
                          _extractedFields.isEmpty ? 'Scan Complete — No Values Found' : 'AI Extraction Complete',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669), fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _extractedFields.isEmpty
                          ? 'The OCR engine read the image but did not recognize any labeled values (e.g. "LDL: 160"). You can inspect the raw text below or fill in the form manually.'
                          : 'The following values were actually recognized from your medical record:',
                      style: const TextStyle(color: Color(0xFF065F46), fontSize: 13),
                    ),
                    if (_extractedFields.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _extractedFields.entries
                            .map((e) => _extractedChip(
                                  LabReportParser.fieldLabels[e.key] ?? e.key,
                                  LabReportParser.formatValue(e.key, e.value),
                                ))
                            .toList(),
                      ),
                    ],
                    if (_lastOcrText != null && _lastOcrText!.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => setState(() => _showRawText = !_showRawText),
                        child: Row(
                          children: [
                            Icon(_showRawText ? Icons.expand_less : Icons.expand_more, size: 18, color: const Color(0xFF059669)),
                            const SizedBox(width: 4),
                            Text(_showRawText ? 'Hide raw OCR text' : 'View raw OCR text', style: const TextStyle(color: Color(0xFF059669), fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 250),
                        crossFadeState: _showRawText ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                        firstChild: Container(
                          margin: const EdgeInsets.only(top: 8),
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFD1FAE5))),
                          child: Text(_lastOcrText!, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF334155))),
                        ),
                        secondChild: const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
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
            // AI Scanner Feature
            AnimatedEntrance(child: _buildScannerCard()),
            const SizedBox(height: 32),

            AnimatedEntrance(
              delay: const Duration(milliseconds: 80),
              child: const Text('Manual Assessment Entry', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ),
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
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 120),
                            child: _buildCard(
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
                          ),
                          const SizedBox(height: 24),
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 180),
                            child: _buildCard(
                              'Medical History', Icons.medical_services_outlined,
                              Column(
                                children: [
                                  SwitchListTile(title: const Text('Diabetes'), value: _data['med_diabetes'], onChanged: (v) => setState(() => _data['med_diabetes'] = v)),
                                  SwitchListTile(title: const Text('High Blood Pressure'), value: _data['med_hbp'], onChanged: (v) => setState(() => _data['med_hbp'] = v)),
                                  SwitchListTile(title: const Text('Family History (Early CVD)'), value: _data['fam_cvd'], onChanged: (v) => setState(() => _data['fam_cvd'] = v)),
                                ],
                              ),
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
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 150),
                            child: _buildCard(
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
                          ),
                          const SizedBox(height: 24),
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 210),
                            child: _buildCard(
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
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
            ),

            const SizedBox(height: 24),
            AnimatedEntrance(
              delay: const Duration(milliseconds: 260),
              child: _buildCard(
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
            ),

            const SizedBox(height: 32),
            AnimatedEntrance(
              delay: const Duration(milliseconds: 320),
              child: Align(
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
            ),
            const SizedBox(height: 64),
          ],
        ),
      ),
    );
  }
}

/// One tappable option inside the "Select Image Source" dialog. Reacts to
/// hover (desktop/web) and press with a small scale + border animation so
/// the dialog feels alive instead of a static list.
class _SourceOptionCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SourceOptionCard({
    required this.icon,
    required this.iconColor,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_SourceOptionCard> createState() => _SourceOptionCardState();
}

class _SourceOptionCardState extends State<_SourceOptionCard> {
  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool active = _hovering || _pressed;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : (active ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: active ? widget.accent.withOpacity(0.06) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: active ? widget.accent : const Color(0xFFE2E8F0), width: active ? 2 : 1),
              boxShadow: active
                  ? [BoxShadow(color: widget.accent.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 8))]
                  : [],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: widget.iconColor.withOpacity(0.12), shape: BoxShape.circle),
                  child: Icon(widget.icon, color: widget.iconColor, size: 28),
                ),
                const SizedBox(height: 14),
                Text(widget.title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                const SizedBox(height: 6),
                Text(widget.subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The dark overlay + moving scan line shown on top of the captured image
/// while the OCR engine is actually processing it.
class _ScanningOverlay extends StatefulWidget {
  const _ScanningOverlay();

  @override
  State<_ScanningOverlay> createState() => _ScanningOverlayState();
}

class _ScanningOverlayState extends State<_ScanningOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final height = constraints.maxHeight.isFinite ? constraints.maxHeight : 280.0;
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Container(color: Colors.black.withOpacity(0.55)),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final top = _controller.value * (height - 4).clamp(0.0, double.infinity);
                return Positioned(
                  top: top,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Colors.transparent, Color(0xFF60A5FA), Colors.transparent]),
                      boxShadow: [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.8), blurRadius: 14, spreadRadius: 2)],
                    ),
                  ),
                );
              },
            ),
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text('🔍 AI OCR: Extracting handwriting...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Reading lipid values, demographics, and medical history', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
