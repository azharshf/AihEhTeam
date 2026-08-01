"""
LipidWise AI — Chatbot Backend (Azhar's module)
RAG chatbot with patient context injection.

Other teammates will integrate:
- Auth / sign-in
- Intake form UI
- Doctor dashboard
- Report generation (summary + Socratic)

This module exposes:
  POST /patient/profile  — receive patient data (from teammate's intake form)
  POST /chat             — RAG chatbot with patient context
  GET  /patient/{sid}    — get current patient profile + analysis
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from rag import generate_response
from patient import (
    PatientProfile, LipidPanel,
    format_patient_context, analyze_lipids
)

app = FastAPI(title="LipidWise AI — Chatbot", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory stores (teammates can swap to DB later)
patients: dict[str, PatientProfile] = {}
chat_histories: dict[str, list] = {}


# ── Models ──

class PatientProfileRequest(BaseModel):
    session_id: str
    name: str | None = None
    age: int | None = None
    sex: str | None = None
    weight_kg: float | None = None
    height_cm: float | None = None
    waist_cm: float | None = None
    ldl_c: float | None = None
    hdl_c: float | None = None
    triglycerides: float | None = None
    total_cholesterol: float | None = None
    smoker: bool | None = None
    alcohol: str | None = None
    exercise_mins_per_week: int | None = None
    diet_quality: str | None = None
    sleep_hours: float | None = None
    stress_level: str | None = None
    has_diabetes: bool | None = None
    has_hypertension: bool | None = None
    has_ckd: bool | None = None
    has_hiv: bool | None = None
    has_family_history_heart: bool | None = None
    has_family_history_cholesterol: bool | None = None
    on_medication: bool | None = None
    medication_names: str | None = None


class ChatRequest(BaseModel):
    session_id: str
    message: str


class ChatResponse(BaseModel):
    reply: str
    risk_level: str | None = None
    alerts: list[str] = []


# Keyword triage so risk_level/alerts reflect emergencies mentioned in free-text
# chat, not just the structured intake form. Intentionally broad/simple —
# false positives just mean an extra alert badge, not a missed emergency.
EMERGENCY_KEYWORDS = {
    "chest_pain": ["chest pain", "chest tightness", "chest pressure", "crushing pain"],
    "stroke_symptoms": ["face drooping", "arm weakness", "slurred speech", "stroke", "can't speak", "cannot speak"],
    "severe_abdominal_pain": ["severe stomach pain", "severe abdominal pain", "unbearable stomach"],
    "severe_shortness_of_breath": ["can't breathe", "cannot breathe", "shortness of breath", "gasping for air"],
}


def _flag_emergency_from_message(patient: PatientProfile, message: str) -> None:
    text = message.lower()
    for field, keywords in EMERGENCY_KEYWORDS.items():
        if any(kw in text for kw in keywords):
            setattr(patient, field, True)


# ── Helpers ──

def _get_patient(sid: str) -> PatientProfile:
    if sid not in patients:
        patients[sid] = PatientProfile()
    return patients[sid]


def _get_history(sid: str) -> list:
    if sid not in chat_histories:
        chat_histories[sid] = []
    return chat_histories[sid]


def _update_patient(patient: PatientProfile, req: PatientProfileRequest):
    for field in req.model_fields:
        if field == "session_id":
            continue
        value = getattr(req, field)
        if value is not None:
            if field in ("ldl_c", "hdl_c", "triglycerides", "total_cholesterol"):
                if not patient.lipid_panel:
                    patient.lipid_panel = LipidPanel()
                setattr(patient.lipid_panel, field, value)
            else:
                setattr(patient, field, value)


# ── Endpoints ──

@app.get("/")
def health_check():
    return {"status": "ok", "service": "LipidWise AI Chatbot"}


@app.post("/patient/profile")
def set_patient_profile(req: PatientProfileRequest):
    """Receive patient data from intake form (teammate's module).
    Partial updates OK — send only the fields you have."""
    patient = _get_patient(req.session_id)
    _update_patient(patient, req)
    analysis = analyze_lipids(patient)
    return {
        "status": "updated",
        "bmi": patient.bmi,
        "risk_level": analysis["risk_level"].value,
        "alerts": analysis["alerts"],
        "flags": analysis["flags"],
        "recommendations": analysis["recommendations"],
        "statin_recommendation": analysis["statin_recommendation"],
    }


@app.get("/patient/{session_id}")
def get_patient(session_id: str):
    """Get current patient profile + auto-analysis."""
    patient = _get_patient(session_id)
    analysis = analyze_lipids(patient)
    return {
        "profile": patient.model_dump(),
        "bmi": patient.bmi,
        "risk_level": analysis["risk_level"].value,
        "alerts": analysis["alerts"],
        "flags": analysis["flags"],
        "recommendations": analysis["recommendations"],
        "statin_recommendation": analysis["statin_recommendation"],
    }


@app.post("/chat", response_model=ChatResponse)
def chat(req: ChatRequest):
    """Main RAG chatbot. Knows the patient's profile + medical knowledge base."""
    patient = _get_patient(req.session_id)
    _flag_emergency_from_message(patient, req.message)
    patient_ctx = format_patient_context(patient)
    history = _get_history(req.session_id)
    analysis = analyze_lipids(patient)

    reply = generate_response(
        user_message=req.message,
        chat_history=history,
        patient_context_str=patient_ctx,
    )

    # Store conversation
    history.append({"role": "user", "content": req.message})
    history.append({"role": "assistant", "content": reply})

    return ChatResponse(
        reply=reply,
        risk_level=analysis["risk_level"].value,
        alerts=analysis["alerts"],
    )


@app.get("/chat/history/{session_id}")
def get_chat_history(session_id: str):
    """Get chat history for a session (teammates can use for reports)."""
    return {"history": _get_history(session_id)}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
