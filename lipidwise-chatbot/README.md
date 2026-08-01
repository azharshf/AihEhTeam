# LipidWise AI — RAG Chatbot Backend

AI-powered dyslipidemia prevention chatbot using RAG (Retrieval-Augmented Generation).

## Quick Start (5 minutes)

### 1. Install dependencies
```bash
pip install -r requirements.txt
```

### 2. Set up your API key
```bash
cp .env.example .env
# Edit .env and add your OpenRouter API key
# Get one free at: https://openrouter.ai/keys
```

### 3. Ingest the knowledge base
```bash
python ingest.py
```
This chunks the medical knowledge files and stores embeddings in ChromaDB locally.

### 4. Run the server
```bash
python main.py
```
Server starts at `http://localhost:8000`

## API Endpoints

### `POST /chat` — Main chat
```json
{
  "message": "What is LDL cholesterol?",
  "history": []
}
```
Response: `{"reply": "..."}`

### `POST /report/summary` — AI Summary Report
```json
{
  "history": [
    {"role": "user", "content": "My LDL is 195"},
    {"role": "assistant", "content": "..."}
  ]
}
```
Response: `{"report": "## LipidWise AI — Health Summary Report\n..."}`

### `POST /report/socratic` — Socratic Educational Report
Same request format as summary. Returns guided Q&A walkthrough.

## Flutter Integration

```dart
// POST to /chat
final response = await http.post(
  Uri.parse('http://localhost:8000/chat'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'message': userMessage,
    'history': chatHistory,
  }),
);
final reply = jsonDecode(response.body)['reply'];
```

## Stack
- **LLM**: OpenRouter (free tier — Gemini Flash / Llama / Mistral)
- **Embeddings**: all-MiniLM-L6-v2 (built into ChromaDB, runs locally)
- **Vector Store**: ChromaDB (local, zero setup)
- **Backend**: FastAPI + Uvicorn
- **Knowledge Base**: 2026 Dyslipidemia Guidelines + medical reference docs
