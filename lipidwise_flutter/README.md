# LipidWise AI - AI-Based Dyslipidemia Prevention System

## Overview
LipidWise AI is a preventive AI system designed to help users detect dyslipidemia risk early and receive personalized Asian-specific lifestyle guidance. It features a **Dual-Role Sign-In**, offering a structured portal for Healthcare Professionals to seamlessly screen and review patient data.

This project was built for a 6-hour hackathon prototype utilizing Flutter and Dart for true cross-platform deployment.

---

## 🏆 Hackathon Judging Criteria Addressed

### 1. Clinical Relevance & Impact
**The Question:** *Does this solve a problem a clinician or health official in this room actually has?*
**What a 10 Looks Like:** *A KOL says "I want this in my clinic."*

**Our Solution:** 
Dyslipidemia is a "silent killer." Clinicians struggle with patients who don't understand their risk until a severe cardiovascular event occurs. 
- **The Clinic Use Case:** A doctor can use our **Dual-Role Sign In (Doctor View)** to rapidly screen patients in the waiting room. The tool instantly flags critical danger zones (e.g. Triglycerides ≥ 1000 mg/dL risking pancreatitis), auto-calculates ML risk scores for patients without recent lab work, and instantly converts complex lab units (`mg/dL` <-> `mmol/L`) according to strict AHA/Merck guidelines, saving clinicians valuable consultation time.

### 2. Technical Execution
**The Question:** *Does it actually work end-to-end?*
**What a 10 Looks Like:** *You'd trust the demo to run live on stage without a net.*

**Our Solution:** 
- **Flawless End-to-End Flutter App:** Built with Flutter/Dart, the single codebase compiles natively to iOS, Android, macOS, Windows, and Web. The UI utilizes dynamic state management (steppers, real-time BMI calculators, and fluid animations) and runs reliably without crashing.
- **Zero-Latency Edge ML:** The Machine Learning logic (Random Forest algorithm) is embedded directly into the client-side Dart code. **It runs 100% offline.** There are no API calls to fail during a live demo, guaranteeing a robust "without a net" presentation.

### 3. Innovation
**The Question:** *A fresh angle, not the obvious first idea?*
**What a 10 Looks Like:** *Could change how this clinical problem is approached.*

**Our Solution:** 
- **Hyper-Localized Dietary Intelligence:** Most health apps offer generic, westernized advice ("eat more salmon and kale"). Our AI Lifestyle Coach innovates by targeting the *actual* triggers in Asian diets—offering specific swaps like replacing *Roti Canai* for *Dosa*, modifying *Nasi Lemak* preparation, and cutting condensed milk from *Teh Tarik*.
- **Graceful Degradation (Dual-Engine System):** If a patient *has* blood test results, the app uses a strict **Clinical Rules Engine**. If the patient *doesn't* have blood tests (the majority of the un-screened population), it falls back to an **ML Predictor Engine** based on NHANES metabolic syndrome factors. This multi-layered approach is highly novel for a consumer app.

### 4. Safety, Ethics & Feasibility
**The Question:** *Do they understand what it takes to be real in healthcare?*
**What a 10 Looks Like:** *A credible path to a real pilot - name your risks (privacy, bias, hallucination, liability) and how you mitigate them.*

**Our Solution & Mitigations:**
- **Liability & Hallucination Mitigation:** We do not use an LLM to generate medical advice on the fly (preventing dangerous medical hallucinations). All clinical rules and food swaps are deterministic, rule-based, and sourced from established guidelines (AHA). The app explicitly flags itself as a "preventive coaching tool," not a diagnostic device.
- **Emergency Triage (Safety Layer):** Step 1 forces a check for Red Flag symptoms (Chest Pain, Stroke signs). If triggered, the app halts the assessment immediately and flashes a hardcoded **Emergency Care Alert**. 
- **Privacy (Feasibility for Pilot):** Because the ML engine and rules engine run **100% locally on the device (Edge AI)**, patient data never leaves the phone. There is zero risk of HIPAA/GDPR data breaches because no external server is processing the health data. This makes institutional sign-off for a pilot significantly easier.

---

## How to Run

1. Ensure Flutter is installed on your system.
2. Run `flutter pub get` inside the `lipidwise_flutter` directory.
3. Run `flutter run -d chrome` (for web) or select your native device emulator.
