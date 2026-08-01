import 'dart:math';

class MLPredictor {
  static const Map<String, double> _weights = {
    'age': 0.15,
    'bmi': 0.20,
    'smoking': 0.12,
    'diabetes': 0.10,
    'diet_fried': 0.08,
    'diet_sugar': 0.07,
    'exercise': 0.08,
    'hypertension': 0.08,
    'alcohol': 0.06,
    'stress': 0.03,
    'family_history': 0.03,
  };

  static Map<String, dynamic> predictRisk(Map<String, dynamic> userData) {
    double riskScore = 0;
    List<Map<String, dynamic>> contributions = [];

    // Age
    int age = int.tryParse(userData['age']?.toString() ?? '30') ?? 30;
    double ageFactor = age > 50 ? 1.0 : (age > 40 ? 0.6 : (age > 30 ? 0.3 : 0.0));
    double ageRisk = ageFactor * _weights['age']!;
    riskScore += ageRisk;
    contributions.add({'name': 'Age Factor', 'weight': ageRisk});

    // BMI
    double bmi = double.tryParse(userData['bmi']?.toString() ?? '22') ?? 22;
    double bmiFactor = bmi >= 30 ? 1.0 : (bmi >= 25 ? 0.6 : 0.0);
    double bmiRisk = bmiFactor * _weights['bmi']!;
    riskScore += bmiRisk;
    if (bmiRisk > 0) contributions.add({'name': 'BMI (Weight)', 'weight': bmiRisk});

    // Smoking
    int smoking = userData['smoking'] == true ? 1 : 0;
    double smokingRisk = smoking * _weights['smoking']!;
    riskScore += smokingRisk;
    if (smokingRisk > 0) contributions.add({'name': 'Smoking', 'weight': smokingRisk});

    // Diabetes
    int diabetes = userData['med_diabetes'] == true ? 1 : 0;
    double diabetesRisk = diabetes * _weights['diabetes']!;
    riskScore += diabetesRisk;
    if (diabetesRisk > 0) contributions.add({'name': 'Diabetes', 'weight': diabetesRisk});

    // Diet Fried
    int fried = int.tryParse(userData['diet_fried']?.toString() ?? '0') ?? 0;
    double friedRisk = (fried / 2) * _weights['diet_fried']!;
    riskScore += friedRisk;
    if (friedRisk > 0) contributions.add({'name': 'Fried/Fast Food', 'weight': friedRisk});

    // Diet Sugar
    int sugar = int.tryParse(userData['diet_sugar']?.toString() ?? '0') ?? 0;
    double sugarRisk = (sugar / 2) * _weights['diet_sugar']!;
    riskScore += sugarRisk;
    if (sugarRisk > 0) contributions.add({'name': 'Sugary Drinks', 'weight': sugarRisk});

    // Exercise
    int exercise = int.tryParse(userData['exercise']?.toString() ?? '0') ?? 0;
    double exerciseRisk = ((3 - exercise) / 3) * _weights['exercise']!;
    riskScore += exerciseRisk;
    if (exerciseRisk > 0) contributions.add({'name': 'Physical Inactivity', 'weight': exerciseRisk});

    // Hypertension
    int hbp = userData['med_hbp'] == true ? 1 : 0;
    double hbpRisk = hbp * _weights['hypertension']!;
    riskScore += hbpRisk;
    if (hbpRisk > 0) contributions.add({'name': 'High Blood Pressure', 'weight': hbpRisk});

    // Alcohol
    int alcohol = int.tryParse(userData['alcohol']?.toString() ?? '0') ?? 0;
    double alcoholRisk = (alcohol / 2) * _weights['alcohol']!;
    riskScore += alcoholRisk;
    if (alcoholRisk > 0) contributions.add({'name': 'Alcohol Intake', 'weight': alcoholRisk});

    // Stress
    int stress = int.tryParse(userData['stress']?.toString() ?? '0') ?? 0;
    double stressRisk = (stress / 2) * _weights['stress']!;
    riskScore += stressRisk;
    if (stressRisk > 0) contributions.add({'name': 'Chronic Stress', 'weight': stressRisk});

    // Family
    int fam = (userData['fam_cholesterol'] == true || userData['fam_cvd'] == true) ? 1 : 0;
    double famRisk = fam * _weights['family_history']!;
    riskScore += famRisk;
    if (famRisk > 0) contributions.add({'name': 'Family History', 'weight': famRisk});

    double normalizedScore = min(riskScore / 0.8, 1.0);
    String category = "Low";
    
    if (normalizedScore > 0.6) {
      category = "High";
    } else if (normalizedScore > 0.3) {
      category = "Moderate";
    }

    contributions.sort((a, b) => b['weight'].compareTo(a['weight']));

    return {
      'category': category,
      'score': normalizedScore,
      'topFactors': contributions.take(5).toList(),
      'message': 'Based on your lifestyle and health profile, your estimated risk of having unhealthy blood fat levels is $category. A lipid profile blood test is recommended for clinical confirmation.',
    };
  }
}
