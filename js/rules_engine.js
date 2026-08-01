// rules_engine.js

/**
 * Rule-Based Lipid Analyzer
 * Uses standard clinical guidelines to classify lipid panels.
 */

const UNIT_CONVERSION = {
    // mg/dL to mmol/L conversion factors
    tc: 0.02586,
    hdl: 0.02586,
    ldl: 0.02586,
    tg: 0.01129
};

const DANGER_ZONES = {
    tg_very_high_mg: 1000,
    tg_high_mg: 500,
    ldl_high_mg: 190,
    tc_high_mg: 240,
    hdl_low_m_mg: 40,
    hdl_low_f_mg: 50
};

class RulesEngine {
    
    // Converts input to mg/dL if provided in mmol/L for standardized logic
    static convertToMgDl(value, type, unit) {
        if (!value) return null;
        const num = parseFloat(value);
        if (unit === 'mg/dL') return num;
        
        // Convert mmol/L to mg/dL
        return num / UNIT_CONVERSION[type];
    }

    static analyzeLipids(tc, ldl, hdl, tg, unit, sex) {
        let result = {
            category: "Low", // Low, Moderate, High, Very High
            message: "",
            breakdown: []
        };

        const tc_mg = this.convertToMgDl(tc, 'tc', unit);
        const ldl_mg = this.convertToMgDl(ldl, 'ldl', unit);
        const hdl_mg = this.convertToMgDl(hdl, 'hdl', unit);
        const tg_mg = this.convertToMgDl(tg, 'tg', unit);

        let highestRisk = 0; // 0=Low, 1=Mod, 2=High, 3=Very High

        // Triglycerides Analysis
        if (tg_mg) {
            let status = 'Ideal';
            if (tg_mg >= 1000) {
                status = 'Very High';
                highestRisk = Math.max(highestRisk, 3);
            } else if (tg_mg >= 500) {
                status = 'High';
                highestRisk = Math.max(highestRisk, 2);
            } else if (tg_mg >= 150) {
                status = 'Borderline';
                highestRisk = Math.max(highestRisk, 1);
            }
            result.breakdown.push({ marker: 'Triglycerides', value: tg_mg, target: '< 150 mg/dL', status: status });
        }

        // LDL Analysis
        if (ldl_mg) {
            let status = 'Ideal';
            if (ldl_mg >= 190) {
                status = 'Very High';
                highestRisk = Math.max(highestRisk, 2);
            } else if (ldl_mg >= 160) {
                status = 'High';
                highestRisk = Math.max(highestRisk, 2);
            } else if (ldl_mg >= 130) {
                status = 'Borderline';
                highestRisk = Math.max(highestRisk, 1);
            }
            result.breakdown.push({ marker: 'LDL-C', value: ldl_mg, target: '< 100 mg/dL', status: status });
        }

        // Total Cholesterol Analysis
        if (tc_mg) {
            let status = 'Ideal';
            if (tc_mg >= 240) {
                status = 'High';
                highestRisk = Math.max(highestRisk, 2);
            } else if (tc_mg >= 200) {
                status = 'Borderline';
                highestRisk = Math.max(highestRisk, 1);
            }
            result.breakdown.push({ marker: 'Total Cholesterol', value: tc_mg, target: '< 200 mg/dL', status: status });
        }

        // HDL Analysis
        if (hdl_mg) {
            let status = 'Ideal';
            const hdl_cutoff = sex === 'male' ? 40 : 50;
            if (hdl_mg < hdl_cutoff) {
                status = 'Low'; // Bad
                highestRisk = Math.max(highestRisk, 1);
            }
            result.breakdown.push({ marker: 'HDL-C', value: hdl_mg, target: `> ${hdl_cutoff} mg/dL`, status: status });
        }

        // Set category and message
        if (highestRisk === 3) {
            result.category = "Very High";
            result.message = "Your triglyceride level is very high (>=1000 mg/dL). This increases the risk of pancreatitis. Please seek urgent medical advice.";
        } else if (highestRisk === 2) {
            result.category = "High";
            result.message = "Your result is in a high concern range (e.g. LDL >= 190 or Triglycerides >= 500). This may significantly increase future cardiovascular or pancreatitis risk. Please consult a doctor.";
        } else if (highestRisk === 1) {
            result.category = "Moderate";
            result.message = "Your lipid profile shows borderline/elevated values. Consider lifestyle improvements and discuss with your doctor.";
        } else {
            result.category = "Low";
            result.message = "Your current profile appears lower concern. Continue healthy eating and regular physical activity.";
        }

        // Convert breakdown back to requested unit for display
        if (unit === 'mmol/L') {
            result.breakdown = result.breakdown.map(b => {
                let targetText = b.target;
                if(targetText.includes('< 150')) targetText = '< 1.7 mmol/L';
                if(targetText.includes('< 100')) targetText = '< 2.6 mmol/L';
                if(targetText.includes('< 200')) targetText = '< 5.2 mmol/L';
                if(targetText.includes('> 40')) targetText = '> 1.0 mmol/L';
                if(targetText.includes('> 50')) targetText = '> 1.3 mmol/L';
                
                let typeKey = 'tc';
                if(b.marker === 'Triglycerides') typeKey = 'tg';
                if(b.marker === 'LDL-C') typeKey = 'ldl';
                if(b.marker === 'HDL-C') typeKey = 'hdl';

                return {
                    ...b,
                    value: (b.value * UNIT_CONVERSION[typeKey]).toFixed(2),
                    target: targetText
                };
            });
        } else {
            // Ensure mg/dL values are whole numbers
            result.breakdown = result.breakdown.map(b => ({
                ...b,
                value: Math.round(b.value)
            }));
        }

        return result;
    }
}
