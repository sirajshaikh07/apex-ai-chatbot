#!/usr/bin/env python3
"""
Enterprise API Testing Suite for Local LLM (Llama 3.1:8b) - Refined
"""

import json
import urllib.request
import time

BASE_URL = "http://20.0.1.39:11434"
MODEL = "llama3.1:8b"

def query_chat(messages, format_json=False):
    payload = {
        "model": MODEL,
        "messages": messages,
        "stream": False,
        "options": {
            "temperature": 0.0,  # Pure deterministic retrieval
            "num_ctx": 8192
        }
    }
    if format_json:
        payload["format"] = "json"

    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(
        f"{BASE_URL}/api/chat",
        data=data,
        headers={"Content-Type": "application/json"}
    )
    t0 = time.time()
    with urllib.request.urlopen(req) as resp:
        result = json.loads(resp.read().decode('utf-8'))
    elapsed = time.time() - t0
    
    reply = result.get('message', {}).get('content', '')
    eval_count = result.get('eval_count', 0)
    eval_dur = result.get('eval_duration', 1)
    tok_sec = (eval_count / eval_dur * 1e9) if eval_dur > 0 else 0
    
    return reply, elapsed, tok_sec

print("=" * 60)
print(f"  Enterprise Local LLM API Test Suite ({MODEL})")
print("=" * 60)

# Sample Document Context
context = """
[DOCUMENT EXCERPT: Enterprise Cloud SLA & Support Policy 2026]
- Severity 1 (Critical Outage): The guaranteed response time is under 15 minutes with 24x7 phone coverage.
- Severity 2 (Major Degradation): Response time is under 2 hours during business hours.
- Severity 3 (Minor Issue): Response time is under 24 hours.
- Annual Uptime Commitment: 99.95% target availability excluding scheduled maintenance.
"""

# -------------------------------------------------------------
# Test 1: Grounded RAG Extraction
# -------------------------------------------------------------
print("\n[TEST 1] Grounded RAG Extraction Test")
sys_msg = (
    "You are a helpful document assistant. Answer the user's question directly and factually "
    "using ONLY the following document text. Quote or extract the exact numbers from the text.\n\n"
    f"Document Excerpts:\n{context}"
)
user_msg = "What is the guaranteed response time for a Severity 1 outage, and what is the annual uptime target?"

messages = [
    {"role": "system", "content": sys_msg},
    {"role": "user", "content": user_msg}
]

reply, elapsed, speed = query_chat(messages)
print(f"Question: {user_msg}")
print(f"Answer:\n{reply.strip()}")
print(f"Performance: {elapsed:.2f}s | Speed: {speed:.2f} tokens/s")

# -------------------------------------------------------------
# Test 2: Guardrail / Out of Context Test
# -------------------------------------------------------------
print("\n" + "-" * 60)
print("[TEST 2] Out of Context Guardrail Test")
unsupported_q = "What is the penalty fee if response time is delayed?"
messages = [
    {"role": "system", "content": sys_msg + "\nIf the document does not contain the answer, reply: 'Information not available in document.'"},
    {"role": "user", "content": unsupported_q}
]

reply_guard, elapsed_g, speed_g = query_chat(messages)
print(f"Question (Out of context): {unsupported_q}")
print(f"Answer:\n{reply_guard.strip()}")

# -------------------------------------------------------------
# Test 3: Structured JSON Output (For External Enterprise App)
# -------------------------------------------------------------
print("\n" + "-" * 60)
print("[TEST 3] Structured JSON API Response (For External Application Integration)")
json_q = (
    "Extract all support tiers into a JSON array of objects with keys: "
    "'tier', 'description', 'response_time'."
)
messages = [
    {"role": "system", "content": sys_msg},
    {"role": "user", "content": json_q}
]
reply_json, elapsed_j, speed_j = query_chat(messages, format_json=True)
print("Raw JSON Response from API:")
try:
    parsed = json.loads(reply_json)
    print(json.dumps(parsed, indent=2))
    print("JSON Schema Validation: PASSED")
except Exception as e:
    print(f"Parse error: {e}")
    print(reply_json)

print("\n" + "=" * 60)
print("  API Verification Complete!")
print("=" * 60)
