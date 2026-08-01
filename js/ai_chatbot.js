// ai_chatbot.js

/**
 * Interactive Preventive Health AI Assistant
 * Provides evidence-based dyslipidemia prevention guidance, food swap advice, and guideline explanations.
 */

const KNOWLEDGE_BASE = [
    {
        keywords: ['prevent', 'risk', 'prevent risk', 'calculator'],
        response: "The PREVENT™ Risk Calculator is the 2026 ACC/AHA standard for estimating 10-year and 30-year ASCVD risk in adults aged 30–79 without prior heart disease. A 10-year risk < 3% and 30-year risk < 10% are considered low risk."
    },
    {
        keywords: ['lpa', 'lipoprotein', 'lipoprotein(a)', 'genetic'],
        response: "Lipoprotein(a) [Lp(a)] is an independent genetic risk factor for cardiovascular disease. The 2026 guidelines recommend measuring Lp(a) at least ONCE in all adults. Values ≥ 125 nmol/L (≥ 50 mg/dL) require aggressive management of other risk factors."
    },
    {
        keywords: ['cac', 'calcium', 'scan', 'coronary'],
        response: "Coronary Artery Calcium (CAC) scoring measures calcified plaque in your heart arteries. For adults with 10-year ASCVD risk ≥ 3% (males ≥40y, females ≥45y) where statin treatment is uncertain, CAC scoring helps refine risk (COR 1, LOE B-R)."
    },
    {
        keywords: ['food', 'diet', 'eat', 'swap', 'cooking'],
        response: "Key dietary improvements: Swap saturated fats (palm oil, butter, condensed milk) with unsaturated oils (olive, canola). Increase soluble fiber (oats, legumes) to lower non-HDL-C and LDL-C naturally."
    },
    {
        keywords: ['statins', 'ezetimibe', 'pcsk9', 'bempedoic', 'medication', 'drug'],
        response: "Under 2026 ACC/AHA guidelines, statins are first-line therapy. If LDL-C or Non-HDL-C remains above target in clinical ASCVD, adding non-statin therapies like Ezetimibe, PCSK9 inhibitors, or Bempedoic Acid is recommended."
    },
    {
        keywords: ['retest', 'check', 'blood test', 'schedule', 'frequency'],
        response: "Repeat lipid testing 4–12 weeks after starting or adjusting lipid-lowering therapy. Once stable, retest every 6–12 months. Routine screening starts at age 9–11 and every 5 years from age 19."
    }
];

class AIChatbot {
    static getResponse(userMessage) {
        const msgLower = userMessage.toLowerCase();
        
        for (const item of KNOWLEDGE_BASE) {
            if (item.keywords.some(kw => msgLower.includes(kw))) {
                return item.response;
            }
        }

        return "I am your LipidWise AI Prevention Assistant. I can answer questions about your 2026 ACC/AHA risk assessment, Non-HDL-C targets, Lp(a) screening, CAC scoring, lipid retesting schedules, or healthy dietary food swaps!";
    }
}

window.AIChatbot = AIChatbot;
