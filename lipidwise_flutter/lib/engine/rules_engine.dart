class RulesEngine {
  static const Map<String, double> unitConversion = {
    'tc': 0.02586,
    'hdl': 0.02586,
    'ldl': 0.02586,
    'tg': 0.01129,
    'non_hdl': 0.02586,
  };

  static double? _convertToMgDl(double? value, String type, String unit) {
    if (value == null) return null;
    if (unit == 'mg/dL') return value;
    return value / (unitConversion[type] ?? 0.02586);
  }

  /// Calculates PREVENT Risk score (10-yr & 30-yr ASCVD risk)
  static Map<String, dynamic>? calculatePREVENTRisk({
    required int age,
    required String sex,
    required double? tcMg,
    required double? hdlMg,
    required double? sysBp,
    required bool smoking,
    required bool diabetes,
  }) {
    if (age < 30 || age > 79) return null;

    bool isMale = sex.toLowerCase() == 'male';
    double sbp = sysBp ?? 120.0;
    double tc = tcMg ?? 200.0;
    double hdl = hdlMg ?? 50.0;

    double base10Yr = 0.015;
    double base30Yr = 0.05;

    base10Yr += (age - 30) * 0.0025;
    base30Yr += (age - 30) * 0.006;

    if (isMale) {
      base10Yr *= 1.25;
      base30Yr *= 1.2;
    }

    if (sbp > 130) {
      base10Yr += (sbp - 130) * 0.001;
      base30Yr += (sbp - 130) * 0.0025;
    }

    double ratio = tc / hdl;
    if (ratio > 4.5) {
      base10Yr += (ratio - 4.5) * 0.01;
      base30Yr += (ratio - 4.5) * 0.02;
    }

    if (smoking) {
      base10Yr *= 1.6;
      base30Yr *= 1.5;
    }
    if (diabetes) {
      base10Yr *= 1.8;
      base30Yr *= 1.7;
    }

    double risk10Yr = (base10Yr * 100).clamp(0.5, 60.0);
    double risk30Yr = (base30Yr * 100).clamp(2.0, 85.0);
    bool isLowRisk = risk10Yr < 3.0 && risk30Yr < 10.0;

    return {
      'risk10Yr': double.parse(risk10Yr.toStringAsFixed(1)),
      'risk30Yr': double.parse(risk30Yr.toStringAsFixed(1)),
      'isLowRisk': isLowRisk,
      'label10Yr': '${risk10Yr.toStringAsFixed(1)}%',
      'label30Yr': '${risk30Yr.toStringAsFixed(1)}%',
      'status': isLowRisk ? "Low Risk (<3% 10-yr & <10% 30-yr)" : (risk10Yr >= 7.5 ? "High Risk (≥7.5%)" : "Intermediate Risk (3-7.4%)"),
    };
  }

  static Map<String, dynamic> analyzeLipids({
    required double? tc,
    required double? ldl,
    required double? hdl,
    required double? tg,
    double? lpa,
    String lpaUnit = 'nmol/L',
    required String unit,
    required String sex,
    int age = 45,
    double? sysBp,
    bool smoking = false,
    bool diabetes = false,
    bool hasASCVD = false,
  }) {
    String category = "Low";
    String message = "";
    List<Map<String, dynamic>> breakdown = [];

    double? tcMg = _convertToMgDl(tc, 'tc', unit);
    double? ldlMg = _convertToMgDl(ldl, 'ldl', unit);
    double? hdlMg = _convertToMgDl(hdl, 'hdl', unit);
    double? tgMg = _convertToMgDl(tg, 'tg', unit);
    bool isMale = sex.toLowerCase() == 'male';

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
        status = 'Very High (Severe Hypercholesterolemia)';
        if (highestRisk < 3) highestRisk = 3;
      } else if (ldlMg >= 160) {
        status = 'High';
        if (highestRisk < 2) highestRisk = 2;
      } else if (ldlMg >= 130) {
        status = 'Borderline';
        if (highestRisk < 1) highestRisk = 1;
      }
      breakdown.add({'marker': 'LDL-C', 'value': ldlMg, 'target': '< 100 mg/dL', 'status': status});
    }

    // Non-HDL-C calculation (Key 2026 Metric)
    if (tcMg != null && hdlMg != null) {
      double nonHdlMg = tcMg - hdlMg;
      String status = 'Ideal';
      if (nonHdlMg >= 190) {
        status = 'Very High';
        if (highestRisk < 2) highestRisk = 2;
      } else if (nonHdlMg >= 160) {
        status = 'High';
        if (highestRisk < 2) highestRisk = 2;
      } else if (nonHdlMg >= 130) {
        status = 'Borderline';
        if (highestRisk < 1) highestRisk = 1;
      }
      breakdown.add({'marker': 'Non-HDL-C (Key 2026 Target)', 'value': nonHdlMg, 'target': '< 130 mg/dL', 'status': status});
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
      double cutoff = isMale ? 40 : 50;
      if (hdlMg < cutoff) {
        status = 'Low';
        if (highestRisk < 1) highestRisk = 1;
      }
      breakdown.add({'marker': 'HDL-C', 'value': hdlMg, 'target': '> ${cutoff.toInt()} mg/dL', 'status': status});
    }

    // Lp(a) Evaluation
    Map<String, dynamic>? lpaAssessment;
    if (lpa != null) {
      double threshold = (lpaUnit == 'nmol/L') ? 125.0 : 50.0;
      bool isHigh = lpa >= threshold;
      lpaAssessment = {
        'value': lpa,
        'unit': lpaUnit,
        'threshold': '$threshold $lpaUnit',
        'isHigh': isHigh,
        'recommendation': isHigh
            ? 'Lp(a) ≥ $threshold $lpaUnit: Optimize early control of modifiable cardiovascular risk factors (COR: 1, LOE: B-NR).'
            : 'Lp(a) within normal limit (< $threshold $lpaUnit). Universal once-in-lifetime measurement completed (COR: 1).',
      };
      if (isHigh && highestRisk < 2) highestRisk = 2;
    }

    // PREVENT Risk Score & CAC Scoring Advice
    Map<String, dynamic>? preventRisk;
    Map<String, dynamic>? cacRecommendation;
    if (!hasASCVD) {
      preventRisk = calculatePREVENTRisk(
        age: age,
        sex: sex,
        tcMg: tcMg,
        hdlMg: hdlMg,
        sysBp: sysBp,
        smoking: smoking,
        diabetes: diabetes,
      );

      bool eligibleAgeForCAC = (isMale && age >= 40) || (!isMale && age >= 45);
      if (preventRisk != null && (preventRisk['risk10Yr'] as double) >= 3.0 && eligibleAgeForCAC) {
        cacRecommendation = {
          'recommended': true,
          'cor': 'COR: 1, LOE: B-R',
          'details': 'For adults with 10-year ASCVD risk ≥3% (males ≥40y, females ≥45y) with uncertainty about LLT, CAC scoring is recommended to refine risk assessment.',
        };
      }
    }

    // Clinical ASCVD Pharmacologic Escalation
    Map<String, dynamic>? therapyEscalation;
    if (hasASCVD) {
      highestRisk = 3;
      bool isNotAtTarget = (ldlMg != null && ldlMg >= 70) || (tcMg != null && hdlMg != null && (tcMg - hdlMg) >= 100);
      therapyEscalation = {
        'hasASCVD': true,
        'isNotAtTarget': isNotAtTarget,
        'cor': 'COR: 1-2',
        'guidelineAdvice': isNotAtTarget
            ? 'In clinical ASCVD not at target with statins, add Ezetimibe, PCSK9 inhibitors, or Bempedoic Acid.'
            : 'Maintain maximally tolerated statin therapy and monitor LDL-C/non-HDL-C targets.',
      };
    }

    if (highestRisk == 3) {
      category = "Very High";
      message = hasASCVD
          ? "Clinical ASCVD detected. 2026 ACC/AHA guidelines recommend aggressive lipid lowering (statins + ezetimibe/PCSK9i/bempedoic acid)."
          : "Severe hypercholesterolemia or extreme triglycerides (>=1000 mg/dL). High risk of ASCVD or pancreatitis.";
    } else if (highestRisk == 2) {
      category = "High";
      message = "Elevated risk markers detected (Non-HDL-C >= 160, LDL-C >= 160, or high Lp(a)). LLT initiation or dose intensification recommended.";
    } else if (highestRisk == 1) {
      category = "Moderate";
      message = "Borderline lipid values detected. Lifestyle modification, non-HDL-C tracking, and PREVENT risk assessment recommended.";
    } else {
      category = "Low";
      message = "Your profile and PREVENT risk estimates are in the low-risk range. Continue healthy lifestyle habits.";
    }

    // Convert back if needed
    if (unit == 'mmol/L') {
      breakdown = breakdown.map((b) {
        String targetText = b['target'];
        if (targetText.contains('< 150')) targetText = '< 1.7 mmol/L';
        if (targetText.contains('< 100')) targetText = '< 2.6 mmol/L';
        if (targetText.contains('< 130')) targetText = '< 3.4 mmol/L';
        if (targetText.contains('< 200')) targetText = '< 5.2 mmol/L';
        if (targetText.contains('> 40')) targetText = '> 1.0 mmol/L';
        if (targetText.contains('> 50')) targetText = '> 1.3 mmol/L';

        String typeKey = 'tc';
        if (b['marker'].contains('Triglycerides')) typeKey = 'tg';
        if (b['marker'].contains('LDL-C')) typeKey = 'ldl';
        if (b['marker'].contains('HDL-C')) typeKey = 'hdl';
        if (b['marker'].contains('Non-HDL-C')) typeKey = 'non_hdl';

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
      'preventRisk': preventRisk,
      'lpaAssessment': lpaAssessment,
      'cacRecommendation': cacRecommendation,
      'therapyEscalation': therapyEscalation,
    };
  }
}

