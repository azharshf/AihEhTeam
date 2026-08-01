// ml_model.js

/**
 * Embedded Machine Learning Model Simulation
 * Since we are in the browser, we simulate a trained Random Forest's feature weights.
 * This predicts Dyslipidemia risk (Low, Moderate, High) when lipid data is missing.
 */

class MLPredictor {
    
    // Simulating feature weights from a Random Forest trained on Metabolic/NHANES data
    static FEATURE_WEIGHTS = {
        age: 0.15,
        bmi: 0.20,
        smoking: 0.12,
        diabetes: 0.10,
        diet_fried: 0.08,
        diet_sugar: 0.07,
        exercise: 0.08, // Negative correlation
        hypertension: 0.08,
        alcohol: 0.06,
        stress: 0.03,
        family_history: 0.03
    };

    static predictRisk(userData) {
        let riskScore = 0;
        let contributions = [];

        // 1. Age
        const age = parseInt(userData.age) || 30;
        let ageFactor = 0;
        if (age > 50) ageFactor = 1.0;
        else if (age > 40) ageFactor = 0.6;
        else if (age > 30) ageFactor = 0.3;
        
        let ageRisk = ageFactor * this.FEATURE_WEIGHTS.age;
        riskScore += ageRisk;
        contributions.push({ name: 'Age Factor', weight: ageRisk, icon: 'fa-user-clock' });

        // 2. BMI
        const bmi = parseFloat(userData.bmi) || 22;
        let bmiFactor = 0;
        if (bmi >= 30) bmiFactor = 1.0; // Obese
        else if (bmi >= 25) bmiFactor = 0.6; // Overweight
        
        let bmiRisk = bmiFactor * this.FEATURE_WEIGHTS.bmi;
        riskScore += bmiRisk;
        if (bmiRisk > 0) contributions.push({ name: 'BMI (Weight)', weight: bmiRisk, icon: 'fa-weight' });

        // 3. Smoking
        const smoking = parseInt(userData.smoking) || 0;
        let smokingRisk = smoking * this.FEATURE_WEIGHTS.smoking;
        riskScore += smokingRisk;
        if (smokingRisk > 0) contributions.push({ name: 'Smoking', weight: smokingRisk, icon: 'fa-smoking' });

        // 4. Diabetes
        const diabetes = parseInt(userData.med_diabetes) || 0;
        let diabetesRisk = diabetes * this.FEATURE_WEIGHTS.diabetes;
        riskScore += diabetesRisk;
        if (diabetesRisk > 0) contributions.push({ name: 'Diabetes', weight: diabetesRisk, icon: 'fa-tint' });

        // 5. Diet - Fried
        const fried = parseInt(userData.diet_fried) || 0; // 0, 1, 2
        let friedRisk = (fried / 2) * this.FEATURE_WEIGHTS.diet_fried;
        riskScore += friedRisk;
        if (friedRisk > 0) contributions.push({ name: 'Fried/Fast Food', weight: friedRisk, icon: 'fa-hamburger' });

        // 6. Diet - Sugar
        const sugar = parseInt(userData.diet_sugar) || 0; // 0, 1, 2
        let sugarRisk = (sugar / 2) * this.FEATURE_WEIGHTS.diet_sugar;
        riskScore += sugarRisk;
        if (sugarRisk > 0) contributions.push({ name: 'Sugary Drinks', weight: sugarRisk, icon: 'fa-mug-hot' });

        // 7. Exercise (Protective)
        const exercise = parseInt(userData.exercise) || 0; // 0,1,2,3
        let lackOfExerciseFactor = (3 - exercise) / 3; // 1.0 if sedentary, 0 if active
        let exerciseRisk = lackOfExerciseFactor * this.FEATURE_WEIGHTS.exercise;
        riskScore += exerciseRisk;
        if (exerciseRisk > 0) contributions.push({ name: 'Physical Inactivity', weight: exerciseRisk, icon: 'fa-couch' });

        // 8. Hypertension
        const hbp = parseInt(userData.med_hbp) || 0;
        let hbpRisk = hbp * this.FEATURE_WEIGHTS.hypertension;
        riskScore += hbpRisk;
        if (hbpRisk > 0) contributions.push({ name: 'High Blood Pressure', weight: hbpRisk, icon: 'fa-heartbeat' });
        
        // 9. Alcohol
        const alcohol = parseInt(userData.alcohol) || 0;
        let alcoholRisk = (alcohol / 2) * this.FEATURE_WEIGHTS.alcohol;
        riskScore += alcoholRisk;
        if (alcoholRisk > 0) contributions.push({ name: 'Alcohol Intake', weight: alcoholRisk, icon: 'fa-wine-glass' });

        // 10. Stress
        const stress = parseInt(userData.stress) || 0;
        let stressRisk = (stress / 2) * this.FEATURE_WEIGHTS.stress;
        riskScore += stressRisk;
        if (stressRisk > 0) contributions.push({ name: 'Chronic Stress', weight: stressRisk, icon: 'fa-brain' });
        
        // Family History
        const fam = parseInt(userData.fam_cholesterol) || parseInt(userData.fam_cvd) || 0;
        let famRisk = fam * this.FEATURE_WEIGHTS.family_history;
        riskScore += famRisk;
        if (famRisk > 0) contributions.push({ name: 'Family History', weight: famRisk, icon: 'fa-users' });

        // Normalize risk score (0 to ~1.0)
        // Adjust threshold based on tuning
        let category = "Low";
        let gaugeValue = 0; // 0 to 180 degrees
        
        // Max theoretical risk score is ~0.9
        let normalizedScore = Math.min(riskScore / 0.8, 1.0);
        gaugeValue = normalizedScore * 180;

        if (normalizedScore > 0.6) {
            category = "High";
        } else if (normalizedScore > 0.3) {
            category = "Moderate";
        }

        // Sort contributions by weight
        contributions.sort((a, b) => b.weight - a.weight);

        return {
            category: category,
            score: normalizedScore,
            gaugeValue: gaugeValue,
            topFactors: contributions.slice(0, 5), // Top 5
            message: `Based on your lifestyle and health profile, your estimated risk of having unhealthy blood fat levels is ${category}. A lipid profile blood test is recommended for clinical confirmation.`
        };
    }
}
