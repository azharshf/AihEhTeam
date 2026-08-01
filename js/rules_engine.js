// rules_engine.js

/**
 * 2026 ACC/AHA Clinical Rule-Based Dyslipidemia Analyzer
 * Sourced from the 2026 ACC/AHA Guideline on the Management of Dyslipidemia.
 */

const UNIT_CONVERSION = {
    // mg/dL to mmol/L conversion factors
    tc: 0.02586,
    hdl: 0.02586,
    ldl: 0.02586,
    tg: 0.01129,
    non_hdl: 0.02586
};

class RulesEngine {
    
    // Converts input to mg/dL if provided in mmol/L
    static convertToMgDl(value, type, unit) {
        if (value === null || value === undefined || value === '') return null;
        const num = parseFloat(value);
        if (isNaN(num)) return null;
        if (unit === 'mg/dL') return num;
        
        // Convert mmol/L to mg/dL
        return num / (UNIT_CONVERSION[type] || 0.02586);
    }

    /**
     * Calculates 10-year and 30-year ASCVD risk using PREVENT Risk Calculator principles
     * Target Population: Adults 30-79 years without known ASCVD
     */
    static calculatePREVENTRisk(age, sex, tc_mg, hdl_mg, sys_bp, isSmoker, hasDiabetes) {
        const ageNum = parseInt(age) || 45;
        if (ageNum < 30 || ageNum > 79) {
            return null; // PREVENT calculator applies to ages 30-79
        }

        const isMale = (sex === 'male');
        const sbp = parseFloat(sys_bp) || 120;
        const tc = tc_mg || 200;
        const hdl = hdl_mg || 50;

        // Base risk score derived from PREVENT Risk factors
        let base10Yr = 0.015;
        let base30Yr = 0.05;

        // Age factor
        base10Yr += (ageNum - 30) * 0.0025;
        base30Yr += (ageNum - 30) * 0.006;

        // Sex factor
        if (isMale) {
            base10Yr *= 1.25;
            base30Yr *= 1.2;
        }

        // Blood Pressure factor
        if (sbp > 130) {
            base10Yr += (sbp - 130) * 0.001;
            base30Yr += (sbp - 130) * 0.0025;
        }

        // Lipid ratio (TC/HDL)
        const ratio = tc / hdl;
        if (ratio > 4.5) {
            base10Yr += (ratio - 4.5) * 0.01;
            base30Yr += (ratio - 4.5) * 0.02;
        }

        // Smoking & Diabetes risk enhancers
        if (isSmoker) {
            base10Yr *= 1.6;
            base30Yr *= 1.5;
        }
        if (hasDiabetes) {
            base10Yr *= 1.8;
            base30Yr *= 1.7;
        }

        const risk10YrPct = Math.min(Math.max((base10Yr * 100), 0.5), 60.0).toFixed(1);
        const risk30YrPct = Math.min(Math.max((base30Yr * 100), 2.0), 85.0).toFixed(1);
        const isLowRisk = parseFloat(risk10YrPct) < 3.0 && parseFloat(risk30YrPct) < 10.0;

        return {
            risk10Yr: parseFloat(risk10YrPct),
            risk30Yr: parseFloat(risk30YrPct),
            isLowRisk: isLowRisk,
            label10Yr: `${risk10YrPct}%`,
            label30Yr: `${risk30YrPct}%`,
            status: isLowRisk ? "Low Risk (<3% 10-yr & <10% 30-yr)" : (risk10YrPct >= 7.5 ? "High Risk (≥7.5%)" : "Intermediate Risk (3-7.4%)")
        };
    }

    /**
     * Complete 2026 ACC/AHA Dyslipidemia Evaluation & Management Analysis
     */
    static analyzeLipids(data) {
        const { tc, ldl, hdl, tg, lpa, lpa_unit, lipid_unit, sex, age, sys_bp, smoking, med_diabetes, med_cvd, has_ascvd, cac_uncertainty } = data;

        let result = {
            category: "Low", // Low, Moderate, High, Very High
            message: "",
            breakdown: [],
            preventRisk: null,
            lpaAssessment: null,
            cacRecommendation: null,
            therapyEscalation: null,
            retestingSchedule: {
                initial: "4–12 weeks after LLT initiation or dose adjustment",
                routine: "Every 6–12 months to assess therapeutic response"
            },
            screeningGuideline: "Screening: Age 9–11 years, then every 5 years from age 19 (more frequent if risk enhancers present)."
        };

        const tc_mg = this.convertToMgDl(tc, 'tc', lipid_unit);
        const ldl_mg = this.convertToMgDl(ldl, 'ldl', lipid_unit);
        const hdl_mg = this.convertToMgDl(hdl, 'hdl', lipid_unit);
        const tg_mg = this.convertToMgDl(tg, 'tg', lipid_unit);
        const isMale = (sex === 'male');
        const ageNum = parseInt(age) || 30;

        let highestRisk = 0; // 0=Low, 1=Mod, 2=High, 3=Very High

        // 1. Triglycerides Analysis
        if (tg_mg !== null) {
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

        // 2. LDL-C Analysis
        if (ldl_mg !== null) {
            let status = 'Ideal';
            if (ldl_mg >= 190) {
                status = 'Very High (Severe Hypercholesterolemia)';
                highestRisk = Math.max(highestRisk, 3);
            } else if (ldl_mg >= 160) {
                status = 'High';
                highestRisk = Math.max(highestRisk, 2);
            } else if (ldl_mg >= 130) {
                status = 'Borderline';
                highestRisk = Math.max(highestRisk, 1);
            }
            result.breakdown.push({ marker: 'LDL-C', value: ldl_mg, target: '< 100 mg/dL', status: status });
        }

        // 3. Non-HDL-C Calculation (2026 Guideline Key Metric)
        if (tc_mg !== null && hdl_mg !== null) {
            const non_hdl_mg = tc_mg - hdl_mg;
            let status = 'Ideal';
            if (non_hdl_mg >= 190) {
                status = 'Very High';
                highestRisk = Math.max(highestRisk, 2);
            } else if (non_hdl_mg >= 160) {
                status = 'High';
                highestRisk = Math.max(highestRisk, 2);
            } else if (non_hdl_mg >= 130) {
                status = 'Borderline';
                highestRisk = Math.max(highestRisk, 1);
            }
            result.breakdown.push({ marker: 'Non-HDL-C (Key 2026 Target)', value: non_hdl_mg, target: '< 130 mg/dL', status: status });
        }

        // 4. Total Cholesterol Analysis
        if (tc_mg !== null) {
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

        // 5. HDL-C Analysis
        if (hdl_mg !== null) {
            let status = 'Ideal';
            const hdl_cutoff = isMale ? 40 : 50;
            if (hdl_mg < hdl_cutoff) {
                status = 'Low';
                highestRisk = Math.max(highestRisk, 1);
            }
            result.breakdown.push({ marker: 'HDL-C', value: hdl_mg, target: `> ${hdl_cutoff} mg/dL`, status: status });
        }

        // 6. Lipoprotein(a) [Lp(a)] Evaluation (2026 Recommendation: Measure at least once in all adults)
        if (lpa !== null && lpa !== undefined && lpa !== '') {
            const lpaVal = parseFloat(lpa);
            const unitType = lpa_unit || 'nmol/L';
            const threshold = (unitType === 'nmol/L') ? 125 : 50; // 125 nmol/L or 50 mg/dL
            const isHighLpa = lpaVal >= threshold;

            result.lpaAssessment = {
                value: lpaVal,
                unit: unitType,
                threshold: `${threshold} ${unitType}`,
                isHigh: isHighLpa,
                recommendation: isHighLpa 
                    ? `Lp(a) ≥ ${threshold} ${unitType}: Optimize early control of modifiable cardiovascular risk factors (COR: 1, LOE: B-NR).`
                    : `Lp(a) level is within normal limit (< ${threshold} ${unitType}). Universal once-in-lifetime measurement completed (COR: 1).`
            };

            if (isHighLpa) {
                highestRisk = Math.max(highestRisk, 2);
            }
        } else {
            result.lpaAssessment = {
                recommendation: "2026 ACC/AHA Recommendation: Measure lipoprotein(a) [Lp(a)] at least once in all adults for ASCVD risk assessment (COR: 1, LOE: B-NR)."
            };
        }

        // 7. PREVENT Risk Calculator
        if (!has_ascvd && !med_cvd) {
            const prevent = this.calculatePREVENTRisk(age, sex, tc_mg, hdl_mg, sys_bp, smoking === 'yes' || smoking === true, med_diabetes === 'yes' || med_diabetes === true);
            if (prevent) {
                result.preventRisk = prevent;
                
                // CAC Scoring Recommendation Check (10-yr risk >= 3%, males >= 40, females >= 45, uncertainty about LLT)
                const eligibleAgeForCAC = (isMale && ageNum >= 40) || (!isMale && ageNum >= 45);
                if (prevent.risk10Yr >= 3.0 && eligibleAgeForCAC) {
                    result.cacRecommendation = {
                        recommended: true,
                        cor: "COR: 1, LOE: B-R",
                        details: "For adults with 10-year ASCVD risk ≥3% (males ≥40y, females ≥45y) and uncertainty about LLT initiation/intensification, CAC scoring is recommended to refine risk assessment and guide LLT decisions."
                    };
                }
            }
        }

        // 8. Clinical ASCVD Pharmacologic Escalation Guidance
        const isASCVD = has_ascvd === 'yes' || has_ascvd === true || med_cvd === 'yes' || med_cvd === true;
        if (isASCVD) {
            highestRisk = Math.max(highestRisk, 3);
            const isNotAtTarget = (ldl_mg && ldl_mg >= 70) || (tc_mg && hdl_mg && (tc_mg - hdl_mg) >= 100);
            
            result.therapyEscalation = {
                hasASCVD: true,
                isNotAtTarget: isNotAtTarget,
                cor: "COR: 1-2 (depending on risk)",
                guidelineAdvice: isNotAtTarget 
                    ? "In clinical ASCVD patients not at LDL-C/non-HDL-C target with maximally tolerated statins, add Ezetimibe, PCSK9 inhibitors, or Bempedoic Acid as appropriate."
                    : "Maintain maximally tolerated statin therapy and monitor LDL-C/non-HDL-C targets."
            };
        }

        // Category messaging
        if (highestRisk === 3) {
            result.category = "Very High";
            result.message = isASCVD 
                ? "Clinical ASCVD / Very High Risk detected. 2026 ACC/AHA guidelines recommend aggressive lipid lowering (statins + ezetimibe / PCSK9i / bempedoic acid)."
                : "Severe hypercholesterolemia or extreme triglycerides (≥1000 mg/dL). High risk of ASCVD or acute pancreatitis. Urgent specialist consultation recommended.";
        } else if (highestRisk === 2) {
            result.category = "High";
            result.message = "Elevated risk markers detected (e.g. Non-HDL-C ≥ 160, LDL-C ≥ 160, or high Lp(a) ≥ 125 nmol/L). LLT initiation or dose intensification is recommended.";
        } else if (highestRisk === 1) {
            result.category = "Moderate";
            result.message = "Borderline lipid values detected. Lifestyle modification, non-HDL-C tracking, and PREVENT risk assessment recommended.";
        } else {
            result.category = "Low";
            result.message = "Your lipid profile and PREVENT risk estimates are in the low-risk range. Continue healthy lifestyle habits and retest per recommended guidelines.";
        }

        // Unit display conversion for breakdown table
        if (lipid_unit === 'mmol/L') {
            result.breakdown = result.breakdown.map(b => {
                let targetText = b.target;
                if (targetText.includes('< 150')) targetText = '< 1.7 mmol/L';
                if (targetText.includes('< 100')) targetText = '< 2.6 mmol/L';
                if (targetText.includes('< 130')) targetText = '< 3.4 mmol/L';
                if (targetText.includes('< 200')) targetText = '< 5.2 mmol/L';
                if (targetText.includes('> 40')) targetText = '> 1.0 mmol/L';
                if (targetText.includes('> 50')) targetText = '> 1.3 mmol/L';
                
                let typeKey = 'tc';
                if (b.marker.includes('Triglycerides')) typeKey = 'tg';
                if (b.marker.includes('LDL-C')) typeKey = 'ldl';
                if (b.marker.includes('HDL-C')) typeKey = 'hdl';
                if (b.marker.includes('Non-HDL-C')) typeKey = 'non_hdl';

                return {
                    ...b,
                    value: (b.value * UNIT_CONVERSION[typeKey]).toFixed(2),
                    target: targetText
                };
            });
        } else {
            result.breakdown = result.breakdown.map(b => ({
                ...b,
                value: Math.round(b.value)
            }));
        }

        return result;
    }
}

