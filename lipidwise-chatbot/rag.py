"""
RAG engine: retrieves relevant chunks from ChromaDB, 
then generates response via OpenRouter.
"""
import os
import chromadb
from chromadb.utils import embedding_functions
from openai import OpenAI
from dotenv import load_dotenv

load_dotenv()

CHROMA_DIR = "chroma_db"
COLLECTION_NAME = "lipidwise"
TOP_K = 4  # number of chunks to retrieve

# OpenRouter uses OpenAI-compatible API
client = OpenAI(
    base_url="https://openrouter.ai/api/v1",
    api_key=os.getenv("OPENROUTER_API_KEY"),
)

# Free OpenRouter models to try, in order. The free tier is a shared pool and
# individual models get rate-limited (429) under load, so we fall back through
# this list rather than failing on the first busy model.
LLM_MODEL = os.getenv("LLM_MODEL", "google/gemma-4-26b-a4b-it:free")
FALLBACK_MODELS = [
    LLM_MODEL,
    "google/gemma-4-31b-it:free",
    "nvidia/nemotron-3-nano-30b-a3b:free",
]

# ChromaDB setup
ef = embedding_functions.DefaultEmbeddingFunction()
chroma_client = chromadb.PersistentClient(path=CHROMA_DIR)
collection = chroma_client.get_collection(
    name=COLLECTION_NAME,
    embedding_function=ef,
)

SYSTEM_PROMPT = """You are LipidWise AI, a friendly and knowledgeable health prevention assistant specializing in dyslipidemia (abnormal cholesterol and triglyceride levels).

YOUR ROLE:
- Help users understand their lipid profile results (LDL-C, HDL-C, triglycerides, total cholesterol).
- Provide personalized lifestyle and dietary advice for preventing or managing dyslipidemia.
- Explain risk levels in simple, non-technical language.
- Guide users on when they should see a doctor.
- Reference the 2026 Dyslipidemia Guidelines when relevant.
- Use the PATIENT CONTEXT below to personalize every response to this specific user.

IMPORTANT SAFETY RULES:
1. You are NOT a doctor. You do NOT diagnose or prescribe medication.
2. Always include a disclaimer that users should consult a healthcare professional.
3. EMERGENCY: If the user mentions chest pain, stroke symptoms (face drooping, arm weakness, speech difficulty), severe abdominal pain, or severe shortness of breath, IMMEDIATELY advise them to call emergency services or go to the nearest hospital. Do not continue normal conversation.
4. Never tell users to stop taking prescribed medication.
5. Be culturally sensitive — many users are Malaysian, so use local food examples when giving dietary advice.
6. If the auto-analysis flagged any ALERTS, make sure to communicate them clearly to the user.

CONVERSATION STYLE:
- Be warm, supportive, and encouraging.
- Use simple language. Avoid medical jargon unless explaining it.
- Ask follow-up questions to better understand the user's situation.
- When explaining lipid numbers, always state what the number means AND what action to take.
- Use both mg/dL and mmol/L units when discussing lipid levels.
- Address the patient by name if available.
- If the patient has provided lipid data, reference their specific numbers when relevant.
- If the patient has NOT provided lipid data yet, gently encourage them to share their blood test results or get tested.

{patient_context}

CONTEXT FROM KNOWLEDGE BASE:
{context}

Based on the patient's profile, the auto-analysis results, the knowledge base, and the user's message, provide a helpful, accurate, personalized, and caring response."""


def retrieve(query: str, top_k: int = TOP_K) -> str:
    """Retrieve relevant chunks from ChromaDB."""
    results = collection.query(
        query_texts=[query],
        n_results=top_k,
    )

    if not results["documents"] or not results["documents"][0]:
        return "No relevant information found in knowledge base."

    chunks = results["documents"][0]
    sources = results["metadatas"][0]

    context_parts = []
    for chunk, meta in zip(chunks, sources):
        source_name = meta.get("source", "unknown")
        context_parts.append(f"[Source: {source_name}]\n{chunk}")

    return "\n\n---\n\n".join(context_parts)


def _complete(messages: list[dict], max_tokens: int, temperature: float) -> str:
    """Call OpenRouter, trying each fallback model in order until one succeeds."""
    last_error = None
    for model in dict.fromkeys(FALLBACK_MODELS):  # de-dupe, preserve order
        try:
            response = client.chat.completions.create(
                model=model,
                messages=messages,
                max_tokens=max_tokens,
                temperature=temperature,
            )
            content = response.choices[0].message.content
            if content:
                return content
        except Exception as e:
            last_error = e
            continue
    return f"Sorry, I encountered an error: {last_error}. Please try again."


def generate_response(
    user_message: str,
    chat_history: list[dict] | None = None,
    patient_context_str: str = "",
) -> str:
    """RAG pipeline: retrieve context → inject patient data → generate response."""

    # Step 1: Retrieve relevant knowledge
    context = retrieve(user_message)

    # Step 2: Build messages with patient context
    system_msg = SYSTEM_PROMPT.format(
        context=context,
        patient_context=patient_context_str if patient_context_str else "No patient data provided yet.",
    )

    messages = [{"role": "system", "content": system_msg}]

    # Add chat history (last 10 messages to keep context window manageable)
    if chat_history:
        messages.extend(chat_history[-10:])

    messages.append({"role": "user", "content": user_message})

    # Step 3: Generate via OpenRouter
    return _complete(messages, max_tokens=1024, temperature=0.7)


def generate_summary_report(chat_history: list[dict], patient_context_str: str = "") -> str:
    """Generate an AI summary report from the conversation."""

    context = ""
    # Retrieve context based on the full conversation
    user_messages = [m["content"] for m in chat_history if m["role"] == "user"]
    if user_messages:
        combined_query = " ".join(user_messages[-5:])
        context = retrieve(combined_query)

    report_prompt = """Based on the conversation so far, the patient's profile, and the knowledge base context, generate a HEALTH SUMMARY REPORT for this user.

{patient_context}

KNOWLEDGE BASE CONTEXT:
{context}

FORMAT:
## LipidWise AI — Health Summary Report

### Your Numbers at a Glance
(Summarize any lipid values the user shared, what each means)

### Risk Assessment
(Based on what was discussed, state their estimated risk level and why)

### Key Recommendations
(3-5 specific, actionable lifestyle steps personalized to what they shared)

### When to See a Doctor
(Specific guidance based on their situation)

### Important Disclaimer
This report is for educational purposes only and does not constitute medical advice. Please consult a healthcare professional for personalized medical guidance.

Keep it simple, warm, and actionable. Use both mg/dL and mmol/L where relevant."""

    messages = [
        {"role": "system", "content": report_prompt.format(
            context=context,
            patient_context=patient_context_str if patient_context_str else "No patient data provided.",
        )},
        *chat_history[-10:],
        {"role": "user", "content": "Please generate my health summary report based on our conversation."},
    ]

    return _complete(messages, max_tokens=2048, temperature=0.5)


def generate_socratic_report(chat_history: list[dict], patient_context_str: str = "") -> str:
    """Generate a Socratic-style educational report."""

    context = ""
    user_messages = [m["content"] for m in chat_history if m["role"] == "user"]
    if user_messages:
        combined_query = " ".join(user_messages[-5:])
        context = retrieve(combined_query)

    socratic_prompt = """Based on the conversation, the patient's profile, and the knowledge base, generate a SOCRATIC HEALTH REPORT — an interactive educational walkthrough that helps the user truly UNDERSTAND their health situation through guided questions and explanations.

{patient_context}

KNOWLEDGE BASE CONTEXT:
{context}

FORMAT:
## LipidWise AI — Understanding Your Health

### Question 1: Do you know what [relevant lipid marker] does in your body?
**Think about it...**
(Give them a moment, then explain in simple terms)

### Question 2: Your [marker] level is [value]. What do you think this means for someone your age?
**Here's what the 2026 guidelines say:**
(Explain with context from the guidelines)

### Question 3: What lifestyle habits might be affecting your levels?
**Let's connect the dots:**
(Link their reported habits to their lipid levels)

### Question 4: If you changed just ONE thing this week, what would make the biggest difference?
**Our recommendation:**
(Give the single highest-impact action based on their situation)

### What You Learned Today
(2-3 sentence summary of key takeaways)

### Disclaimer
This educational report does not constitute medical advice. Always consult a healthcare professional.

Make it feel like a caring teacher walking them through understanding, not lecturing. Use their actual data from the conversation."""

    messages = [
        {"role": "system", "content": socratic_prompt.format(
            context=context,
            patient_context=patient_context_str if patient_context_str else "No patient data provided.",
        )},
        *chat_history[-10:],
        {"role": "user", "content": "Generate my Socratic health education report."},
    ]

    return _complete(messages, max_tokens=2048, temperature=0.6)
