class LifestyleCoach {
  static const List<Map<String, String>> _foodSwaps = [
    {
      'from': 'Nasi Lemak',
      'to': 'Brown Rice Nasi Lemak (Less Oil)',
      'desc': 'Use brown rice, sambal tumis with less oil, boiled egg, and grilled chicken instead of fried chicken to reduce saturated fats.',
      'trigger': 'diet_fried',
    },
    {
      'from': 'Roti Canai with Curry',
      'to': 'Dosa (Thosai) or Chapati with Dhal',
      'desc': 'Dosa and chapati use much less oil and ghee compared to roti canai, lowering your trans-fat intake.',
      'trigger': 'diet_fried',
    },
    {
      'from': 'Teh Tarik or Boba Tea',
      'to': 'Teh O Kosong or Green Tea',
      'desc': 'Eliminating condensed milk and added sugars prevents triglyceride spikes and reduces total calories.',
      'trigger': 'diet_sugar',
    },
    {
      'from': 'Deep Fried Snacks (Pisang Goreng)',
      'to': 'Roasted Nuts or Fresh Guava',
      'desc': 'Swap deep-fried batter for heart-healthy fats (almonds) or high-fiber fruits (guava with plum powder).',
      'trigger': 'diet_fried',
    },
    {
      'from': 'Char Kway Teow / Fried Noodles',
      'to': 'Soup Noodles (Clear Broth) with Greens',
      'desc': 'Clear broth noodles significantly cut down on cooking oil and sodium, protecting your blood vessels.',
      'trigger': 'diet_fried',
    },
    {
      'from': 'Beef Rendang / Fatty Meats',
      'to': 'Steamed Fish with Soy & Ginger',
      'desc': 'Fish is rich in Omega-3 fatty acids which helps increase good cholesterol (HDL) and lower triglycerides.',
      'trigger': 'always',
    },
  ];

  static List<Map<String, String>> getFoodSwaps(Map<String, dynamic> userData) {
    List<Map<String, String>> swaps = [];
    bool eatsFried = int.tryParse(userData['diet_fried']?.toString() ?? '0')! > 0;
    bool drinksSugar = int.tryParse(userData['diet_sugar']?.toString() ?? '0')! > 0;

    for (var swap in _foodSwaps) {
      if (swap['trigger'] == 'always' ||
          (swap['trigger'] == 'diet_fried' && eatsFried) ||
          (swap['trigger'] == 'diet_sugar' && drinksSugar)) {
        swaps.add(swap);
      }
    }
    return swaps.take(4).toList();
  }

  static List<Map<String, String>> getActionPlan(Map<String, dynamic> userData, String riskCategory) {
    List<Map<String, String>> plan = [];
    bool isHighRisk = riskCategory == 'High' || riskCategory == 'Very High';

    // Day 1
    String d1 = "Review your LipidWise results. ";
    if (isHighRisk) d1 += "Schedule an appointment with a healthcare professional this week.";
    else d1 += "Set a goal for one healthy change this week.";
    plan.add({'title': 'Day 1: Awareness', 'desc': d1});

    // Day 2
    String d2 = "";
    if (int.tryParse(userData['diet_sugar']?.toString() ?? '0')! > 0) {
      d2 += "Replace one sugary drink today with plain water or green tea.";
    } else {
      d2 += "Incorporate an extra serving of vegetables into your lunch.";
    }
    plan.add({'title': 'Day 2: Dietary Shift', 'desc': d2});

    // Day 3
    String d3 = "";
    if (int.tryParse(userData['exercise']?.toString() ?? '0')! < 2) {
      d3 += "Take a brisk 20-minute walk today, even if it's just around the neighborhood.";
    } else {
      d3 += "Add 15 minutes of cardio or strength training to your routine.";
    }
    plan.add({'title': 'Day 3: Active Movement', 'desc': d3});

    // Day 4
    String d4 = "";
    if (int.tryParse(userData['stress']?.toString() ?? '0')! > 0) {
      d4 += "Practice 10 minutes of deep breathing or meditation to lower cortisol levels.";
    } else {
      d4 += "Aim for 7-8 hours of quality sleep tonight to allow your body to repair.";
    }
    plan.add({'title': 'Day 4: Stress & Sleep Check', 'desc': d4});

    // Day 5
    String d5 = "";
    if (userData['smoking'] == true) {
      d5 += "Identify smoking triggers today and delay your first cigarette by 1 hour.";
    } else if (int.tryParse(userData['diet_fried']?.toString() ?? '0')! > 0) {
      d5 += "Choose a steamed, grilled, or baked meal today instead of fried.";
    } else {
      d5 += "Try snacking on a handful of unsalted nuts instead of packaged snacks.";
    }
    plan.add({'title': 'Day 5: Habit Substitution', 'desc': d5});

    plan.add({'title': 'Day 6: Weekend Prep', 'desc': 'Plan your meals for the upcoming week and prepare healthy snacks.'});
    plan.add({'title': 'Day 7: Consistency', 'desc': 'Review your progress. Consistency over perfection prevents cardiovascular disease.'});

    return plan;
  }
}
