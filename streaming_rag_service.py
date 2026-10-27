#!/usr/bin/env python3
"""
Enterprise APEX Real-Time Token Streaming Service
Strategy 1: Smart Context Budgeting (< 1,500 chars context)
Strategy 3: In-Database Semantic Caching (< 20ms response)
Strategy 4: Real-Time Token Streaming in APEX (TTFT < 1.5s)
"""

import os
import sys
import json
import time
import requests
from flask import Flask, request, Response, jsonify
from flask_cors import CORS
import oracledb

app = Flask(__name__)
CORS(app)

# Load database & Ollama credentials
SECRETS_PATH = "/home/ubuntu/.secrets.env"
VALUES_PATH = "/home/ubuntu/project/values.env"

CONFIG = {
    "DB_USER": "AIDEMO",
    "DB_PWD": "Apex_26ai_2026Free",
    "DB_IP": "20.0.1.130",
    "DB_PORT": "1521",
    "DB_SERVICE": "FREEPDB1",
    "OLLAMA_URL": "http://20.0.1.39:11434",
    "OLLAMA_MODEL": "qwen2.5:7b"
}

for path in [SECRETS_PATH, VALUES_PATH]:
    if os.path.exists(path):
        with open(path) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    k, v = line.split("=", 1)
                    v = v.strip("'").strip('"')
                    if k == "AIDEMO_PWD":
                        CONFIG["DB_PWD"] = v
                    elif k == "VM1_IP":
                        CONFIG["DB_IP"] = v
                    elif k == "DB_PORT":
                        CONFIG["DB_PORT"] = v
                    elif k == "DB_SERVICE":
                        CONFIG["DB_SERVICE"] = v
                    elif k == "OLLAMA_MODEL":
                        CONFIG["OLLAMA_MODEL"] = v

oracledb.defaults.fetch_lobs = False

def get_db_connection():
    dsn = f"{CONFIG['DB_IP']}:{CONFIG['DB_PORT']}/{CONFIG['DB_SERVICE']}"
    return oracledb.connect(user=CONFIG["DB_USER"], password=CONFIG["DB_PWD"], dsn=dsn)

def get_rag_context_and_prompt(question, session_id, user_name):
    """
    1. Checks Strategy 3 Semantic Cache (< 20ms) using in-DB vector embeddings
    2. Applies Strategy 1 Smart Context Budgeting (Top 2 dense chunks, ~1,200 chars)
    Returns: (is_cache_hit, prompt_or_cached_answer, sources, cached_msg_id)
    """
    t0 = time.time()
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        clean_q = question.strip()
        # Clean query prefixes (e.g. Q1:, 1.)
        import re
        clean_q = re.sub(r'^([Qq]\d+|\d+)\s*[:\.\)]\s*', '', clean_q).strip()

        # =====================================================================
        # Strategy 3: Check In-Database Semantic Cache (< 20ms)
        # =====================================================================
        cache_sql = """
        SELECT ai_response, sources, msg_id
        FROM chat_history
        WHERE prompt_embedding IS NOT NULL
          AND (user_feedback IS NULL OR user_feedback = 'UP')
          AND NVL(is_refusal, 'N') = 'N'
          AND ai_response IS NOT NULL
          AND DBMS_LOB.GETLENGTH(ai_response) > 20
          AND (
              VECTOR_DISTANCE(prompt_embedding, VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING :q1 AS DATA), COSINE) <= 0.0800
           OR REGEXP_REPLACE(LOWER(user_prompt), '[^a-z0-9]', '') = REGEXP_REPLACE(LOWER(:q2), '[^a-z0-9]', '')
          )
        ORDER BY VECTOR_DISTANCE(prompt_embedding, VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING :q3 AS DATA), COSINE) ASC
        FETCH FIRST 1 ROW ONLY
        """
        cursor.execute(cache_sql, [clean_q, clean_q, clean_q])
        cache_row = cursor.fetchone()
        if cache_row:
            cached_ans, cached_sources, cached_msg_id = cache_row
            db_elapsed = (time.time() - t0) * 1000
            src = (cached_sources or "Enterprise Knowledge Base") + " [⚡ Instant Semantic Cache Hit]"
            print(f"DB Retrieval: CacheHit=True in {db_elapsed:.1f}ms. Sources: {src}")
            return True, str(cached_ans), src, int(cached_msg_id or 0)

        # =====================================================================
        # Strategy 1: Smart Context Budgeting (< 1,500 chars context)
        # =====================================================================
        # 1. Gather recent conversational turns
        hist_sql = """
        SELECT user_prompt, SUBSTR(ai_response, 1, 200) as ai_resp
        FROM (
            SELECT user_prompt, ai_response
            FROM chat_history
            WHERE session_id = :sid
            ORDER BY msg_id DESC
        ) WHERE ROWNUM <= 2
        ORDER BY ROWNUM DESC
        """
        cursor.execute(hist_sql, [int(session_id or 0)])
        hist_turns = []
        for i, h_row in enumerate(cursor.fetchall(), 1):
            u_prompt, a_resp = h_row
            hist_turns.append(f"Turn {i} User: {u_prompt}\nAssistant: {a_resp}")
        hist_ctx = "\n".join(hist_turns)

        # 2. Determine Smart Context Budget
        upper_q = clean_q.upper()
        is_list_query = any(w in upper_q for w in ["ALL", "LIST", "EVERY", "SAB", "SAARE"])
        cand_budget = 6 if is_list_query else 2
        fetch_limit = 5 if is_list_query else 3

        # 3. Hybrid Vector + Keyword Retrieval
        retrieval_sql = """
        WITH vec_cand AS (
            SELECT c.chunk_id, c.doc_id, c.chunk_no, c.chunk_text,
                   VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING :q1 AS DATA), COSINE) AS dist
            FROM doc_chunks c
            JOIN source_docs d ON c.doc_id = d.doc_id
            WHERE d.status = 'ACTIVE'
            ORDER BY dist ASC
            FETCH FIRST 20 ROWS ONLY
        ),
        scored_cand AS (
            SELECT v.chunk_id, v.doc_id, v.chunk_no, v.chunk_text,
                   (v.dist - CASE 
                               WHEN UPPER(v.chunk_text) LIKE '%' || UPPER(:q2) || '%' THEN 0.10
                               ELSE 0.0
                             END) AS adj_dist
            FROM vec_cand v
        ),
        top_cand AS (
            SELECT * FROM (
                SELECT * FROM scored_cand ORDER BY adj_dist ASC
            ) WHERE ROWNUM <= :budget
        ),
        retrieved_cand AS (
            SELECT c.chunk_id, t.adj_dist as dist,
                   ROW_NUMBER() OVER (PARTITION BY c.chunk_id ORDER BY t.adj_dist ASC) as rn
            FROM top_cand t
            JOIN doc_chunks c ON c.doc_id = t.doc_id
                             AND c.chunk_no BETWEEN t.chunk_no - 1 AND t.chunk_no + 1
        )
        SELECT r.chunk_id, c.chunk_no, c.chunk_text, d.title as doc_title
        FROM retrieved_cand r
        JOIN doc_chunks c ON r.chunk_id = c.chunk_id
        JOIN source_docs d ON c.doc_id = d.doc_id
        WHERE r.rn = 1 AND d.status = 'ACTIVE'
        ORDER BY r.dist ASC, c.chunk_no ASC
        FETCH FIRST :fetch_lim ROWS ONLY
        """
        cursor.execute(retrieval_sql, [clean_q, clean_q, cand_budget, fetch_limit])
        chunks = cursor.fetchall()

        chunks_text_parts = []
        sources_list = []
        for ch in chunks:
            ch_id, ch_no, ch_text, doc_title = ch
            chunks_text_parts.append(f"\n--- [Document: {doc_title} | Chunk #{ch_no}] ---\n{ch_text}")
            if doc_title and doc_title not in sources_list:
                sources_list.append(doc_title)

        sources_text = ", ".join(sources_list) if sources_list else "Enterprise Knowledge Base"
        chunks_ctx = "".join(chunks_text_parts)

        # 4. Assemble Grounded System Prompt
        prompt = (
            "You are an authoritative Enterprise AI Assistant for Oracle APEX. "
            "Answer the user's question thoroughly, accurately, and completely based SOLELY on the provided enterprise context chunks below. "
            "Do NOT invent or assume facts not present in the text. "
            "Explain all details, numbers, durations, rules, conditions, and exceptions clearly and comprehensively. "
            "Do not truncate the answer, but avoid repetitive boilerplate filler.\n\n"
        )
        if hist_ctx:
            prompt += f"RECENT CONVERSATION HISTORY:\n{hist_ctx}\n\n"
        prompt += f"ENTERPRISE CONTEXT CHUNKS:\n{chunks_ctx}\n\n"
        prompt += f"USER QUESTION: {question}\nENTERPRISE AI ANSWER:"

        db_elapsed = (time.time() - t0) * 1000
        print(f"DB Retrieval: CacheHit=False in {db_elapsed:.1f}ms. Sources: {sources_text}")
        return False, prompt, sources_text, 0

    finally:
        cursor.close()
        conn.close()

def save_chat_turn(session_id, user_name, question, answer, sources, elapsed_ms):
    """Saves the completed conversation turn into chat_history table with prompt_embedding."""
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        out_msg_id = cursor.var(oracledb.DB_TYPE_NUMBER)
        sql = """
        INSERT INTO chat_history (
            session_id, user_name, user_prompt, ai_response, sources, response_time_ms, prompt_embedding
        ) VALUES (
            :1, :2, :3, :4, :5, :6,
            VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING :7 AS DATA)
        ) RETURNING msg_id INTO :8
        """
        cursor.execute(sql, [
            int(session_id or 0),
            user_name or 'USER',
            question,
            answer,
            sources,
            int(elapsed_ms),
            question,
            out_msg_id
        ])
        conn.commit()
        msg_id = out_msg_id.getvalue()[0] if isinstance(out_msg_id.getvalue(), list) else out_msg_id.getvalue()
        return int(msg_id)
    except Exception as e:
        print(f"Error saving chat history: {e}")
        return 0
    finally:
        cursor.close()
        conn.close()

@app.route('/health', methods=['GET'])
def health():
    return jsonify({
        "status": "UP",
        "service": "APEX Real-Time Token Streaming + Semantic Cache Service",
        "model": CONFIG["OLLAMA_MODEL"],
        "ollama_url": CONFIG["OLLAMA_URL"]
    })

@app.route('/api/chat/stream', methods=['POST'])
def chat_stream():
    """
    Real-Time Streaming Endpoint for APEX UI
    - If Semantic Cache Hit: returns full verified answer in < 20ms!
    - If Fresh Query: streams tokens from Ollama via SSE with TTFT < 1.5s!
    """
    t_start = time.time()
    data = request.get_json(force=True, silent=True) or {}
    question = data.get("question", "").strip()
    session_id = data.get("session_id", "0")
    user_name = data.get("user_name", "USER")

    if not question:
        return jsonify({"error": "Empty question"}), 400

    def generate_events():
        full_answer = []
        sources = "Enterprise Knowledge Base"
        t0 = time.time()
        first_token_time = None

        try:
            # 1. Check Semantic Cache & Build Smart Budget Prompt
            is_cache, content, sources, cached_msg_id = get_rag_context_and_prompt(question, session_id, user_name)

            # Strategy 3: Fast Path if Semantic Cache Hit!
            if is_cache:
                total_elapsed = round((time.time() - t_start) * 1000)
                # Yield full cached answer in chunks for smooth visual rendering
                words = content.split(" ")
                for i, w in enumerate(words):
                    chunk_token = w + (" " if i < len(words) - 1 else "")
                    yield f"data: {json.dumps({'token': chunk_token, 'done': False})}\n\n"
                    time.sleep(0.01) # 10ms micro-stagger for ultra-smooth appearance

                done_payload = {
                    "done": True,
                    "msg_id": cached_msg_id,
                    "sources": sources,
                    "elapsed_ms": total_elapsed
                }
                yield f"data: {json.dumps(done_payload)}\n\n"
                return

            # Strategy 4: Fresh Query - Stream tokens from Ollama
            prompt = content
            payload = {
                "model": CONFIG["OLLAMA_MODEL"],
                "prompt": prompt,
                "stream": True,
                "options": {
                    "temperature": 0.1,
                    "top_p": 0.9,
                    "num_ctx": 4096
                }
            }

            resp = requests.post(
                f"{CONFIG['OLLAMA_URL']}/api/generate",
                json=payload,
                stream=True,
                timeout=120
            )

            if resp.status_code != 200:
                err_msg = f"Ollama error: HTTP {resp.status_code}"
                yield f"data: {json.dumps({'error': err_msg})}\n\n"
                return

            for line in resp.iter_lines(decode_unicode=True):
                if line:
                    chunk = json.loads(line)
                    token = chunk.get("response", "")
                    done = chunk.get("done", False)

                    if token:
                        if first_token_time is None:
                            first_token_time = time.time()
                            ttft = (first_token_time - t0) * 1000
                            print(f"Time-To-First-Token (TTFT): {ttft:.1f}ms")

                        full_answer.append(token)
                        yield f"data: {json.dumps({'token': token, 'done': False})}\n\n"

                    if done:
                        total_elapsed = (time.time() - t_start) * 1000
                        complete_text = "".join(full_answer).strip()
                        
                        # Save to database with vector embedding for future cache hits
                        msg_id = save_chat_turn(
                            session_id=session_id,
                            user_name=user_name,
                            question=question,
                            answer=complete_text,
                            sources=sources,
                            elapsed_ms=total_elapsed
                        )

                        done_payload = {
                            "done": True,
                            "msg_id": msg_id,
                            "sources": sources,
                            "elapsed_ms": round(total_elapsed)
                        }
                        yield f"data: {json.dumps(done_payload)}\n\n"
                        break

        except Exception as ex:
            print(f"Stream error: {ex}")
            yield f"data: {json.dumps({'error': str(ex)})}\n\n"

    return Response(
        generate_events(),
        mimetype="text/event-stream",
        headers={
            "Cache-Control": "no-cache, no-transform",
            "Content-Type": "text/event-stream; charset=utf-8",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no"
        }
    )

if __name__ == "__main__":
    print("Starting APEX Real-Time Token Streaming Service on 0.0.0.0:5056...")
    app.run(host="0.0.0.0", port=5056, threaded=True)
