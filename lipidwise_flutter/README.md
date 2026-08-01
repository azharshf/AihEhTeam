# LipidWise AI - AI-Based Dyslipidemia Prevention System

## Overview
LipidWise AI is a preventive AI system designed to help users detect dyslipidemia risk early and receive personalized Asian-specific lifestyle guidance, while offering a structured portal for Healthcare Professionals to review data.

This project was built for a 6-hour hackathon prototype utilizing Flutter and Dart for cross-platform deployment.

---

## 🏆 Hackathon Judging Criteria Addressed

### 1. Clinical Relevance & Impact
**"Does this solve a problem a clinician or health official actually has?"**
Yes. Dyslipidemia is often a "silent killer" with no symptoms until a severe cardiovascular event occurs. 
- **For Patients:** Bridges the gap between complex lab results and understandable lifestyle interventions, preventing late-stage diagnoses.
- **For Clinicians:** The **Dual-Role Sign In** (Patient vs. Doctor) allows clinicians to use the app to rapidly screen patients, calculate ML risk scores instantly, and instantly convert units (`mg/dL` <-> `mmol/L`) using AHA/Merck guidelines.

### 2. Technical Execution
**"Does it actually work end-to-end?"**
- **End-to-End Flutter App:** Built with Flutter/Dart, meaning this single codebase runs perfectly on iOS, Android, and Web.
- **Zero-Latency ML Engine:** The Machine Learning Random Forest algorithm is embedded directly into Dart. It runs locally without requiring a backend server, ensuring offline capability, instantaneous results, and high privacy.
- **Dynamic Routing & UI:** Includes robust state management with a dynamic stepper, real-time BMI calculator, and conditional rendering (Rule-Based Analysis vs ML Prediction).

### 3. Innovation
**"A fresh angle, not the obvious first idea?"**
- **Asian/Malaysian Food Swaps:** Instead of generic Western dietary advice (e.g. "eat more salmon/kale"), the AI Lifestyle Coach specifically targets local triggers (e.g., swapping *Roti Canai* for *Dosa*, *Nasi Lemak* modifications, *Teh Tarik* sugar reductions).
- **Graceful Degradation (Dual-Engine):** If the user has lipid blood test results, the app uses strict Clinical Rules. If the user *doesn't* have blood tests (common in preventive stages), it falls back to a simulated Random Forest Machine Learning Model based on NHANES metabolic syndrome factors.

### 4. Safety, Ethics & Feasibility (Mitigations)
**"Do they understand what it takes to be real in healthcare?"**
- **Liability & Diagnosis Mitigation:** The app strictly states it is a "preventive coaching tool" and *not* a diagnostic device.
- **Emergency Triage Layer:** Step 1 forces a check for Red Flag symptoms (Chest Pain, Stroke signs). If triggered, the app immediately halts the assessment and flashes an **Emergency Care Alert**.
- **Danger Zone Triggers:** Implements strict cutoffs for immediate danger (e.g., Triglycerides ≥ 1000 mg/dL triggers a Pancreatitis warning).
- **Privacy (Data Feasibility):** Because the ML engine and rules engine run 100% locally on the device (Edge AI), patient data never leaves the phone. There is zero risk of HIPAA/GDPR data breaches because there is no external API call.

---

## How to Run

1. Ensure Flutter is installed (`flutter --version`).
2. Run `flutter pub get`.
3. Run `flutter run -d chrome` (for web) or select your device.
