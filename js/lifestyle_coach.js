// lifestyle_coach.js

/**
 * AI Lifestyle & Prevention Coach
 * Generates Asian-specific food swaps and customized 7-day action plans based on user data.
 */

const FOOD_SWAPS = [
    {
        from: "Nasi Lemak",
        to: "Brown Rice Nasi Lemak (Less Oil)",
        desc: "Use brown rice, sambal tumis with less oil, boiled egg, and grilled/baked chicken instead of fried chicken to reduce saturated fats.",
        trigger: "diet_fried"
    },
    {
        from: "Roti Canai with Curry",
        to: "Dosa (Thosai) or Chapati with Dhal",
        desc: "Dosa and chapati use much less oil and ghee compared to roti canai, lowering your trans-fat intake while keeping the familiar taste.",
        trigger: "diet_fried"
    },
    {
        from: "Teh Tarik or Boba Tea",
        to: "Teh O Kosong or Green Tea",
        desc: "Eliminating condensed milk and added sugars prevents triglyceride spikes and reduces total calorie intake.",
        trigger: "diet_sugar"
    },
    {
        from: "Deep Fried Snacks (Pisang Goreng)",
        to: "Roasted Nuts or Fresh Guava",
        desc: "Swap deep-fried batter for heart-healthy fats (almonds) or high-fiber fruits (guava with plum powder).",
        trigger: "diet_fried"
    },
    {
        from: "Char Kway Teow / Fried Noodles",
        to: "Soup Noodles (Clear Broth) with Greens",
        desc: "Clear broth noodles significantly cut down on cooking oil and sodium, protecting your blood vessels.",
        trigger: "diet_fried"
    },
    {
        from: "Beef Rendang / Fatty Meats",
        to: "Steamed Fish with Soy & Ginger",
        desc: "Fish is rich in Omega-3 fatty acids which helps increase good cholesterol (HDL) and lower triglycerides.",
        trigger: "always"
    }
];

class LifestyleCoach {
    
    static getFoodSwaps(userData) {
        let swaps = [];
        const eatsFried = parseInt(userData.diet_fried) > 0;
        const drinksSugar = parseInt(userData.diet_sugar) > 0;
        
        FOOD_SWAPS.forEach(swap => {
            if (swap.trigger === 'always' || 
               (swap.trigger === 'diet_fried' && eatsFried) ||
               (swap.trigger === 'diet_sugar' && drinksSugar)) {
                swaps.push(swap);
            }
        });

        // Return up to 4 relevant swaps
        return swaps.slice(0, 4);
    }

    static getActionPlan(userData, riskCategory) {
        let plan = [];
        const isHighRisk = riskCategory === 'High' || riskCategory === 'Very High';
        
        // Day 1
        let day1 = { title: "Day 1: Awareness & Baseline", desc: "Review your LipidWise results. " };
        if (isHighRisk) day1.desc += "Schedule an appointment with a healthcare professional this week.";
        else day1.desc += "Set a goal for one healthy change this week.";
        plan.push(day1);

        // Day 2
        let day2 = { title: "Day 2: Dietary Shift", desc: "" };
        if (parseInt(userData.diet_sugar) > 0) day2.desc += "Replace one sugary drink today with plain water or green tea. ";
        else day2.desc += "Incorporate an extra serving of vegetables into your lunch. ";
        plan.push(day2);

        // Day 3
        let day3 = { title: "Day 3: Active Movement", desc: "" };
        if (parseInt(userData.exercise) < 2) day3.desc += "Take a brisk 20-minute walk today, even if it's just around the neighborhood or office.";
        else day3.desc += "Add 15 minutes of cardio or strength training to your usual routine.";
        plan.push(day3);

        // Day 4
        let day4 = { title: "Day 4: Stress & Sleep Check", desc: "" };
        if (parseInt(userData.stress) > 0) day4.desc += "Practice 10 minutes of deep breathing or meditation to lower cortisol levels.";
        else day4.desc += "Aim for 7-8 hours of quality sleep tonight to allow your body to repair.";
        plan.push(day4);

        // Day 5
        let day5 = { title: "Day 5: Habit Substitution", desc: "" };
        if (parseInt(userData.smoking) === 1) day5.desc += "Identify smoking triggers today and delay your first cigarette by 1 hour.";
        else if (parseInt(userData.diet_fried) > 0) day5.desc += "Choose a steamed, grilled, or baked meal today instead of fried.";
        else day5.desc += "Try snacking on a handful of unsalted nuts instead of packaged snacks.";
        plan.push(day5);

        // Day 6 & 7
        plan.push({ title: "Day 6: Weekend Active Prep", desc: "Plan your meals for the upcoming week. Prepare healthy snacks." });
        plan.push({ title: "Day 7: Consistency is Key", desc: "Review your progress. Consistency over perfection is the key to preventing cardiovascular disease." });

        return plan;
    }
}
