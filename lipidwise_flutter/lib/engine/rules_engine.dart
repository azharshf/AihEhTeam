class RulesEngine {
  static const Map<String, double> unitConversion = {
    'tc': 0.02586,
    'hdl': 0.02586,
    'ldl': 0.02586,
    'tg': 0.01129,
  };

  static double? _convertToMgDl(double? value, String type, String unit) {
    if (value == null) return null;
    if (unit == 'mg/dL') return value;
    return value / unitConversion[type]!;
  }

  static Map<String, dynamic> analyzeLipids({
    required double? tc,
    required double? ldl,
    required double? hdl,
    required double? tg,
    required String unit,
    required String sex,
  }) {
    String category = "Low";
    String message = "";
    List<Map<String, dynamic>> breakdown = [];

    double? tcMg = _convertToMgDl(tc, 'tc', unit);
    double? ldlMg = _convertToMgDl(ldl, 'ldl', unit);
    double? hdlMg = _convertToMgDl(hdl, 'hdl', unit);
    double? tgMg = _convertToMgDl(tg, 'tg', unit);

    int highestRisk = 0; // 0=Low, 1=Mod, 2=High, 3=Very High

    if (tgMg != null) {
      String status = 'Ideal';
      if (tgMg >= 1000) {
        status = 'Very High';
        highestRisk = 3;
      } else if (tgMg >= 500) {
        status = 'High';
        if (highestRisk < 2) highestRisk = 2;
      } else if (tgMg >= 150) {
        status = 'Borderline';
        if (highestRisk < 1) highestRisk = 1;
      }
      breakdown.add({'marker': 'Triglycerides', 'value': tgMg, 'target': '< 150 mg/dL', 'status': status});
    }

    if (ldlMg != null) {
      String status = 'Ideal';
      if (ldlMg >= 190) {
        status = 'Very High';
        if (highestRisk < 2) highestRisk = 2; // Treat >=190 as high/very high clinical alert
      } else if (ldlMg >= 160) {
        status = 'High';
        if (highestRisk < 2) highestRisk = 2;
      } else if (ldlMg >= 130) {
        status = 'Borderline';
        if (highestRisk < 1) highestRisk = 1;
      }
      breakdown.add({'marker': 'LDL-C', 'value': ldlMg, 'target': '< 100 mg/dL', 'status': status});
    }

    if (tcMg != null) {
      String status = 'Ideal';
      if (tcMg >= 240) {
        status = 'High';
        if (highestRisk < 2) highestRisk = 2;
      } else if (tcMg >= 200) {
        status = 'Borderline';
        if (highestRisk < 1) highestRisk = 1;
      }
      breakdown.add({'marker': 'Total Cholesterol', 'value': tcMg, 'target': '< 200 mg/dL', 'status': status});
    }

    if (hdlMg != null) {
      String status = 'Ideal';
      double cutoff = sex.toLowerCase() == 'male' ? 40 : 50;
      if (hdlMg < cutoff) {
        status = 'Low';
        if (highestRisk < 1) highestRisk = 1;
      }
      breakdown.add({'marker': 'HDL-C', 'value': hdlMg, 'target': '> ${cutoff.toInt()} mg/dL', 'status': status});
    }

    if (highestRisk == 3) {
      category = "Very High";
      message = "Your triglyceride level is very high (>=1000 mg/dL). This increases the risk of pancreatitis. Please seek urgent medical advice.";
    } else if (highestRisk == 2) {
      category = "High";
      message = "Your result is in a high concern range. This may significantly increase future cardiovascular or pancreatitis risk. Please consult a doctor.";
    } else if (highestRisk == 1) {
      category = "Moderate";
      message = "Your lipid profile shows borderline/elevated values. Consider lifestyle improvements and discuss with your doctor.";
    } else {
      category = "Low";
      message = "Your current profile appears lower concern. Continue healthy eating and regular physical activity.";
    }

    // Convert back if needed
    if (unit == 'mmol/L') {
      breakdown = breakdown.map((b) {
        String targetText = b['target'];
        if (targetText.contains('< 150')) targetText = '< 1.7 mmol/L';
        if (targetText.contains('< 100')) targetText = '< 2.6 mmol/L';
        if (targetText.contains('< 200')) targetText = '< 5.2 mmol/L';
        if (targetText.contains('> 40')) targetText = '> 1.0 mmol/L';
        if (targetText.contains('> 50')) targetText = '> 1.3 mmol/L';

        String typeKey = 'tc';
        if (b['marker'] == 'Triglycerides') typeKey = 'tg';
        if (b['marker'] == 'LDL-C') typeKey = 'ldl';
        if (b['marker'] == 'HDL-C') typeKey = 'hdl';

        return {
          'marker': b['marker'],
          'value': (b['value'] * unitConversion[typeKey]!).toStringAsFixed(2),
          'target': targetText,
          'status': b['status'],
        };
      }).toList();
    } else {
      breakdown = breakdown.map((b) {
        return {
          'marker': b['marker'],
          'value': (b['value'] as double).round().toString(),
          'target': b['target'],
          'status': b['status'],
        };
      }).toList();
    }

    return {
      'category': category,
      'message': message,
      'breakdown': breakdown,
    };
  }
}
