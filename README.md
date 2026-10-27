# Universal Enterprise AI Chatbot & RAG Engine
### Powered by Oracle AI Database 26ai, Oracle APEX 26.2, and Local LLM (Qwen 2.5 / Ollama)

---

## 🌟 Overview

This repository contains the production-grade **Universal Enterprise RAG Architecture** built natively on **Oracle AI Database 26ai Free** and **Oracle APEX 26.2**. It delivers grounded, low-latency, hallucination-resistant question answering across heterogeneous enterprise documents (policies, resumes, task trackers, technical specifications, and legal runbooks).

---

## 🏛️ System Architecture

```
[ User Browser / REST API Client ]
                │
         (HTTP / ORDS)
                ▼
      ┌──────────────────┐
      │ Oracle APEX 26.2 │
      └─────────┬────────┘
                │ PL/SQL API
                ▼
┌───────────────────────────────────────────────┐
│     Oracle AI Database 26ai (FREEPDB1)        │
│                                               │
│  • ENTERPRISE_RAG_PKG Engine                  │
│  • In-DB Vector Embeddings (ALL_MINILM_L12_V2)│
│  • Hybrid Search (Cosine Vector + Keyword)   │
│  • Working Memory & Multi-Turn History        │
│  • In-DB Hinglish & Roman-Hindi Query Resolver│
└───────────────────────┬───────────────────────┘
                        │ REST API (apex_ai)
                        ▼
         ┌─────────────────────────────┐
         │ Local Ollama LLM Service    │
         │ Model: qwen2.5:7b / 8b      │
         └─────────────────────────────┘
```

---

## 🚀 Key Features

1. **Universal Document-Agnostic RAG**:
   - Zero hardcoded logic. Works dynamically with any active document in `SOURCE_DOCS`.
   - Semantic chunking with contextual headers (`[Document: <title>]`).
2. **Hybrid Vector & Keyword Search**:
   - Oracle 26ai native `VECTOR_DISTANCE(..., COSINE)`.
   - Entity-boosted candidate ranking with dynamic candidate pools.
3. **Multi-Turn Conversational Working Memory**:
   - In-session follow-up pronoun rewriting (`he`, `she`, `that project`, `uske tasks`).
4. **Fast In-Database Hinglish / Roman-Hindi Resolver**:
   - Sub-millisecond vocabulary mapping for bilingual enterprise users.
5. **Multi-Channel Interfaces**:
   - **APEX Page 1**: Real-time Chat UI with Markdown rendering and user feedback.
   - **APEX Page 2**: Admin Command Center for batch upload, document lifecycle management, and observability telemetry.
   - **ORDS REST API**: Native `/api/chat` POST endpoint with session context support.

---

## 📂 Core Repository Structure

- `enterprise_rag_pkg.sql` — Primary RAG retrieval, working memory, prompt assembly, and inference package.
- `enterprise_rag_schema.sql` — Relational schema DDL (projects, members, memories, vector chunks, chat history).
- `setup_ords_chat.sql` — ORDS REST API module (`POST /ords/aidemo/api/chat`).
- `update_ingest_proc.sql` — Document ingestion, multi-engine extraction (PDF, text, OCR fallback), and vectorization.
- `ocr_service.py` — Flask OCR microservice (Tesseract 5.3 + poppler) for scanned documents and images.
- `chatapp/` — Exported Oracle APEX 26.2 application source and component definitions.
- `05_workspace.sh` – `09_vector_setup.sh` — Automated deployment and setup runbooks.

---

## 📄 License
MIT License
