"""
Patient context model and rule-based lipid analyzer.
Stores patient data and runs danger-zone checks.
"""
from pydantic import BaseModel
from enum import Enum


class RiskLevel(str, Enum):
    LOW = "low"
    MODERATE = "moderate"
    HIGH = "high"
    VERY_HIGH = "very_high"
    EMERGENCY = "emergency"


class LipidPanel(BaseModel):
    ldl_c: float | None = None        # mg/dL
    hdl_c: float | None = None        # mg/dL
    triglycerides: float | None = None # mg/dL
    total_cholesterol: float | None = None  # mg/dL


class PatientProfile(BaseModel):
    # Basic info
    name: str | None = None
    age: int | None = None
    sex: str | None = None             # "male" / "female"
    weight_kg: float | None = None
    height_cm: float | None = None
    waist_cm: float | None = None

    # Lipid panel (optional — user may not have blood test)
    lipid_panel: LipidPanel | None = None

    # Lifestyle
    smoker: bool | None = None
    alcohol: str | None = None         # "none" / "light" / "moderate" / "heavy"
    exercise_mins_per_week: int | None = None
    diet_quality: str | None = None    # "poor" / "fair" / "good"
    sleep_hours: float | None = None
    stress_level: str | None = None    # "low" / "moderate" / "high"

    # Medical history
    has_diabetes: bool | None = None
    has_hypertension: bool | None = None
    has_ckd: bool | None = None        # chronic kidney disease
    has_hiv: bool | None = None
    has_family_history_heart: bool | None = None
    has_family_history_cholesterol: bool | None = None
    on_medication: bool | None = None
    medication_names: str | None = None

    # Emergency symptoms (checked every message)
    chest_pain: bool = False
    stroke_symptoms: bool = False
    severe_abdominal_pain: bool = False
    severe_shortness_of_breath: bool = False

    @property
    def bmi(self) -> float | None:
        if self.weight_kg and self.height_cm:
            h_m = self.height_cm / 100
            return round(self.weight_kg / (h_m ** 2), 1)
        return None

    @property
    def has_lipid_data(self) -> bool:
        if not self.lipid_panel:
            return False
        lp = self.lipid_panel
        return any([lp.ldl_c, lp.hdl_c, lp.triglycerides, lp.total_cholesterol])

    @property
    def has_emergency(self) -> bool:
        return any([
            self.chest_pain,
            self.stroke_symptoms,
            self.severe_abdominal_pain,
            self.severe_shortness_of_breath,
        ])


def mg_to_mmol_cholesterol(mg: float) -> float:
    """Convert mg/dL to mmol/L for cholesterol (LDL, HDL, TC)."""
    return round(mg / 38.67, 2)

def mg_to_mmol_triglycerides(mg: float) -> float:
    """Convert mg/dL to mmol/L for triglycerides."""
    return round(mg / 88.57, 2)


def analyze_lipids(patient: PatientProfile) -> dict:
    """
    Rule-based lipid analysis. Returns structured findings.
    Based on 2026 Dyslipidemia Guidelines.
    """
    findings = {
        "risk_level": RiskLevel.LOW,
        "alerts": [],
        "flags": [],
        "recommendations": [],
        "statin_recommendation": None,
    }

    # Check emergency first
    if patient.has_emergency:
        findings["risk_level"] = RiskLevel.EMERGENCY
        findings["alerts"].append(
            "⚠️ EMERGENCY: You reported serious symptoms. "
            "Please call emergency services (999/112) or go to the nearest hospital IMMEDIATELY."
        )
        return findings

    if not patient.has_lipid_data:
        findings["flags"].append(
            "No lipid panel data available. A blood test (lipid profile) is recommended "
            "for accurate risk assessment."
        )
        # Still assess based on risk factors
        risk_factors = _count_risk_factors(patient)
        if risk_factors >= 3:
            findings["risk_level"] = RiskLevel.MODERATE
            findings["recommendations"].append(
                "You have multiple risk factors. Getting a lipid profile blood test is strongly recommended."
            )
        return findings

    lp = patient.lipid_panel

    # ── Triglycerides (check first — pancreatitis risk) ──
    if lp.triglycerides:
        tg = lp.triglycerides
        if tg >= 1000:
            findings["risk_level"] = RiskLevel.VERY_HIGH
            findings["alerts"].append(
                f"🔴 VERY HIGH triglycerides: {tg} mg/dL ({mg_to_mmol_triglycerides(tg)} mmol/L). "
                f"Urgent medical care recommended — high risk of pancreatitis."
            )
        elif tg >= 500:
            findings["risk_level"] = max(findings["risk_level"], RiskLevel.HIGH, key=_risk_order)
            findings["alerts"].append(
                f"🟠 HIGH triglycerides: {tg} mg/dL ({mg_to_mmol_triglycerides(tg)} mmol/L). "
                f"See a doctor soon — pancreatitis risk may increase."
            )
        elif tg >= 200:
            findings["risk_level"] = max(findings["risk_level"], RiskLevel.MODERATE, key=_risk_order)
            findings["flags"].append(
                f"Triglycerides are high: {tg} mg/dL ({mg_to_mmol_triglycerides(tg)} mmol/L). "
                f"Lifestyle changes recommended."
            )
        elif tg >= 150:
            findings["flags"].append(
                f"Triglycerides are borderline high: {tg} mg/dL ({mg_to_mmol_triglycerides(tg)} mmol/L)."
            )

    # ── LDL-C ──
    if lp.ldl_c:
        ldl = lp.ldl_c
        if ldl >= 190:
            findings["risk_level"] = max(findings["risk_level"], RiskLevel.HIGH, key=_risk_order)
            findings["alerts"].append(
                f"🔴 VERY HIGH LDL-C: {ldl} mg/dL ({mg_to_mmol_cholesterol(ldl)} mmol/L). "
                f"Strong recommendation for medical review and statin therapy (2026 guideline)."
            )
            findings["statin_recommendation"] = "STRONG — LDL-C ≥ 190 mg/dL"
        elif ldl >= 160:
            findings["risk_level"] = max(findings["risk_level"], RiskLevel.MODERATE, key=_risk_order)
            findings["flags"].append(
                f"LDL-C is high: {ldl} mg/dL ({mg_to_mmol_cholesterol(ldl)} mmol/L). "
                f"Moderate recommendation for statin evaluation (2026 guideline)."
            )
            findings["statin_recommendation"] = "MODERATE — LDL-C 160–189 mg/dL"
        elif ldl >= 130:
            findings["flags"].append(
                f"LDL-C is borderline high: {ldl} mg/dL ({mg_to_mmol_cholesterol(ldl)} mmol/L)."
            )

    # ── Total Cholesterol ──
    if lp.total_cholesterol:
        tc = lp.total_cholesterol
        if tc >= 240:
            findings["risk_level"] = max(findings["risk_level"], RiskLevel.MODERATE, key=_risk_order)
            findings["flags"].append(
                f"Total cholesterol is high: {tc} mg/dL ({mg_to_mmol_cholesterol(tc)} mmol/L). "
                f"Medical review and lifestyle changes recommended."
            )
        elif tc >= 200:
            findings["flags"].append(
                f"Total cholesterol is borderline high: {tc} mg/dL ({mg_to_mmol_cholesterol(tc)} mmol/L)."
            )

    # ── HDL-C ──
    if lp.hdl_c and patient.sex:
        hdl = lp.hdl_c
        low_threshold = 40 if patient.sex == "male" else 50
        if hdl < low_threshold:
            findings["risk_level"] = max(findings["risk_level"], RiskLevel.MODERATE, key=_risk_order)
            findings["flags"].append(
                f"HDL-C is low: {hdl} mg/dL ({mg_to_mmol_cholesterol(hdl)} mmol/L). "
                f"This increases cardiovascular risk. Exercise and diet can help raise HDL."
            )

    # ── 2026 Guideline: Statin independent of ASCVD risk ──
    if patient.age and 40 <= patient.age <= 75:
        if patient.has_diabetes:
            if not findings["statin_recommendation"]:
                findings["statin_recommendation"] = "STRONG — diabetes, aged 40–75"
            findings["flags"].append(
                "With diabetes at age 40–75, the 2026 guideline gives a STRONG recommendation for statin therapy."
            )
        if patient.has_ckd:
            findings["flags"].append(
                "With CKD stage ≥3 at age 40–75, the 2026 guideline gives a STRONG recommendation for statin therapy."
            )
        if patient.has_hiv:
            findings["flags"].append(
                "With HIV at age 40–75, the 2026 guideline gives a STRONG recommendation for statin therapy."
            )

    # ── Additional risk factors ──
    risk_factors = _count_risk_factors(patient)
    if risk_factors >= 3 and findings["risk_level"] == RiskLevel.LOW:
        findings["risk_level"] = RiskLevel.MODERATE

    # ── Build recommendations ──
    findings["recommendations"] = _build_recommendations(patient, findings)

    return findings


def _risk_order(level: RiskLevel) -> int:
    order = {
        RiskLevel.LOW: 0,
        RiskLevel.MODERATE: 1,
        RiskLevel.HIGH: 2,
        RiskLevel.VERY_HIGH: 3,
        RiskLevel.EMERGENCY: 4,
    }
    return order.get(level, 0)


def _count_risk_factors(patient: PatientProfile) -> int:
    count = 0
    if patient.smoker:
        count += 1
    if patient.has_diabetes:
        count += 1
    if patient.has_hypertension:
        count += 1
    if patient.has_family_history_heart:
        count += 1
    if patient.bmi and patient.bmi >= 30:
        count += 1
    if patient.exercise_mins_per_week is not None and patient.exercise_mins_per_week < 60:
        count += 1
    if patient.age and patient.age >= 45 and patient.sex == "male":
        count += 1
    if patient.age and patient.age >= 55 and patient.sex == "female":
        count += 1
    return count


def _build_recommendations(patient: PatientProfile, findings: dict) -> list[str]:
    recs = []

    if findings["risk_level"] in (RiskLevel.HIGH, RiskLevel.VERY_HIGH):
        recs.append("See a doctor as soon as possible for a full cardiovascular assessment.")

    if patient.smoker:
        recs.append("Quit smoking — it directly lowers HDL-C and damages blood vessels.")

    if patient.exercise_mins_per_week is not None and patient.exercise_mins_per_week < 150:
        recs.append("Increase physical activity to at least 150 minutes per week of moderate exercise.")

    if patient.diet_quality in ("poor", "fair"):
        recs.append(
            "Improve diet: reduce fried foods and saturated fats, increase fiber, "
            "eat more vegetables, fish, and whole grains."
        )

    if patient.alcohol == "heavy":
        recs.append("Reduce alcohol intake — heavy drinking significantly raises triglycerides.")

    if patient.sleep_hours and patient.sleep_hours < 6:
        recs.append("Improve sleep — aim for 7–8 hours. Poor sleep is linked to higher cholesterol.")

    if patient.stress_level == "high":
        recs.append("Manage stress through exercise, mindfulness, or counseling — chronic stress worsens lipid levels.")

    if patient.bmi and patient.bmi >= 25:
        recs.append(f"Your BMI is {patient.bmi}. Losing 5–10% of body weight can significantly improve lipid levels.")

    if not patient.has_lipid_data:
        recs.append("Get a lipid profile blood test for an accurate assessment.")

    return recs


def format_patient_context(patient: PatientProfile) -> str:
    """Format patient data as readable context for the LLM prompt."""
    lines = ["PATIENT PROFILE:"]

    if patient.name:
        lines.append(f"- Name: {patient.name}")
    if patient.age:
        lines.append(f"- Age: {patient.age}")
    if patient.sex:
        lines.append(f"- Sex: {patient.sex}")
    if patient.weight_kg:
        lines.append(f"- Weight: {patient.weight_kg} kg")
    if patient.height_cm:
        lines.append(f"- Height: {patient.height_cm} cm")
    if patient.bmi:
        lines.append(f"- BMI: {patient.bmi}")
    if patient.waist_cm:
        lines.append(f"- Waist: {patient.waist_cm} cm")

    # Lipid panel
    if patient.has_lipid_data:
        lp = patient.lipid_panel
        lines.append("\nLIPID PANEL RESULTS:")
        if lp.ldl_c:
            lines.append(f"- LDL-C: {lp.ldl_c} mg/dL ({mg_to_mmol_cholesterol(lp.ldl_c)} mmol/L)")
        if lp.hdl_c:
            lines.append(f"- HDL-C: {lp.hdl_c} mg/dL ({mg_to_mmol_cholesterol(lp.hdl_c)} mmol/L)")
        if lp.triglycerides:
            lines.append(f"- Triglycerides: {lp.triglycerides} mg/dL ({mg_to_mmol_triglycerides(lp.triglycerides)} mmol/L)")
        if lp.total_cholesterol:
            lines.append(f"- Total Cholesterol: {lp.total_cholesterol} mg/dL ({mg_to_mmol_cholesterol(lp.total_cholesterol)} mmol/L)")

    # Lifestyle
    lifestyle = []
    if patient.smoker is not None:
        lifestyle.append(f"Smoker: {'Yes' if patient.smoker else 'No'}")
    if patient.alcohol:
        lifestyle.append(f"Alcohol: {patient.alcohol}")
    if patient.exercise_mins_per_week is not None:
        lifestyle.append(f"Exercise: {patient.exercise_mins_per_week} mins/week")
    if patient.diet_quality:
        lifestyle.append(f"Diet quality: {patient.diet_quality}")
    if patient.sleep_hours:
        lifestyle.append(f"Sleep: {patient.sleep_hours} hours/night")
    if patient.stress_level:
        lifestyle.append(f"Stress: {patient.stress_level}")
    if lifestyle:
        lines.append("\nLIFESTYLE:")
        for item in lifestyle:
            lines.append(f"- {item}")

    # Medical history
    conditions = []
    if patient.has_diabetes:
        conditions.append("Diabetes")
    if patient.has_hypertension:
        conditions.append("Hypertension")
    if patient.has_ckd:
        conditions.append("CKD (Chronic Kidney Disease)")
    if patient.has_hiv:
        conditions.append("HIV")
    if patient.has_family_history_heart:
        conditions.append("Family history of heart disease")
    if patient.has_family_history_cholesterol:
        conditions.append("Family history of high cholesterol")
    if patient.on_medication:
        med_str = f"On medication: {patient.medication_names}" if patient.medication_names else "On medication (unspecified)"
        conditions.append(med_str)
    if conditions:
        lines.append("\nMEDICAL HISTORY:")
        for c in conditions:
            lines.append(f"- {c}")

    # Analysis results
    if patient.has_lipid_data or patient.has_emergency:
        analysis = analyze_lipids(patient)
        lines.append(f"\nAUTO-ANALYSIS RESULTS:")
        lines.append(f"- Risk level: {analysis['risk_level'].value.upper()}")
        if analysis["statin_recommendation"]:
            lines.append(f"- 2026 guideline statin recommendation: {analysis['statin_recommendation']}")
        for alert in analysis["alerts"]:
            lines.append(f"- ALERT: {alert}")
        for flag in analysis["flags"]:
            lines.append(f"- {flag}")
        for rec in analysis["recommendations"]:
            lines.append(f"- Recommendation: {rec}")

    return "\n".join(lines)
