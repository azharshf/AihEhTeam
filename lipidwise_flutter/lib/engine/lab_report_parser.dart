/// Parses raw OCR text from a scanned "Buku Rekod Sakit" / lab report and
/// pulls out whichever clinical values it can actually find.
///
/// This is intentionally conservative: a field is only included in the
/// returned map when a matching label + number was really found in the
/// recognized text. Nothing here invents or defaults a value — if the OCR
/// text doesn't mention "LDL", no `ldl` key is produced.
class LabReportParser {
  static Map<String, dynamic> parse(String rawText) {
    final Map<String, dynamic> found = {};
    // OCR sometimes reads decimal points as commas, and collapses newlines
    // in ways that break line-anchored matching, so we normalize first.
    final text = rawText.replaceAll(RegExp(r'(\d),(\d)'), r'$1.$2');

    double? matchNumber(List<String> patterns) {
      for (final pattern in patterns) {
        final match = RegExp(pattern, caseSensitive: false).firstMatch(text);
        final raw = match?.group(1);
        if (raw != null) {
          final value = double.tryParse(raw);
          if (value != null) return value;
        }
      }
      return null;
    }

    final age = matchNumber([r'age[:\s]+(\d{1,3})\b']);
    if (age != null && age > 0 && age < 130) {
      found['age'] = age.toInt();
    }

    final weight = matchNumber([
      r'weight[:\s]+(\d{2,3}(?:\.\d+)?)\s*kg',
      r'weight[:\s]+(\d{2,3}(?:\.\d+)?)\b',
      r'\bBW[:\s]+(\d{2,3}(?:\.\d+)?)\b',
    ]);
    if (weight != null && weight > 20 && weight < 300) {
      found['weight'] = weight;
    }

    final height = matchNumber([
      r'height[:\s]+(\d{2,3}(?:\.\d+)?)\s*cm',
      r'height[:\s]+(\d{2,3}(?:\.\d+)?)\b',
      r'\bHT[:\s]+(\d{2,3}(?:\.\d+)?)\b',
    ]);
    if (height != null && height > 80 && height < 250) {
      found['height'] = height;
    }

    final tc = matchNumber([
      r'total\s*chol(?:esterol)?[^\d]{0,10}(\d{2,3}(?:\.\d+)?)',
      r'\bTC\b[:\s]+(\d{2,3}(?:\.\d+)?)',
    ]);
    if (tc != null && tc > 50 && tc < 500) {
      found['tc'] = tc;
    }

    final ldl = matchNumber([
      r'LDL[\-\s]?C?[:\s]+(\d{2,3}(?:\.\d+)?)',
      r'LDL[^\d]{0,10}(\d{2,3}(?:\.\d+)?)',
    ]);
    if (ldl != null && ldl > 20 && ldl < 400) {
      found['ldl'] = ldl;
    }

    final hdl = matchNumber([
      r'HDL[\-\s]?C?[:\s]+(\d{1,3}(?:\.\d+)?)',
      r'HDL[^\d]{0,10}(\d{1,3}(?:\.\d+)?)',
    ]);
    if (hdl != null && hdl > 10 && hdl < 150) {
      found['hdl'] = hdl;
    }

    final tg = matchNumber([
      r'trigly?ceride[s]?[^\d]{0,10}(\d{2,4}(?:\.\d+)?)',
      r'\bTG\b[:\s]+(\d{2,4}(?:\.\d+)?)',
    ]);
    if (tg != null && tg > 20 && tg < 1000) {
      found['tg'] = tg;
    }

    final lower = text.toLowerCase();
    if (lower.contains('hypertension') ||
        lower.contains('high blood pressure') ||
        RegExp(r'\bhbp\b').hasMatch(lower)) {
      found['med_hbp'] = true;
    }
    if (lower.contains('diabetes') || RegExp(r'\bdm\b').hasMatch(lower)) {
      found['med_diabetes'] = true;
    }
    if (lower.contains('smoker') || lower.contains('smoking')) {
      found['smoking'] = true;
    }

    return found;
  }

  /// Human-readable label + formatted value for display in the extraction
  /// confirmation UI, keyed the same way as [parse]'s output.
  static const Map<String, String> fieldLabels = {
    'age': 'Age',
    'weight': 'Weight',
    'height': 'Height',
    'tc': 'Total Cholesterol',
    'ldl': 'LDL-C',
    'hdl': 'HDL-C',
    'tg': 'Triglycerides',
    'med_hbp': 'High Blood Pressure',
    'med_diabetes': 'Diabetes',
    'smoking': 'Smoking',
  };

  static String formatValue(String key, dynamic value) {
    if (value is bool) return value ? 'Yes' : 'No';
    switch (key) {
      case 'weight':
        return '$value kg';
      case 'height':
        return '$value cm';
      case 'tc':
      case 'ldl':
      case 'hdl':
      case 'tg':
        return '$value mg/dL';
      default:
        return '$value';
    }
  }
}
