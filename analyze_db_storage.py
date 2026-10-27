#!/usr/bin/env python3
"""
Deep Diagnostic Script: Analyzes what is stored in Oracle 26ai DB:
1. All SOURCE_DOCS (title, size, status, content snippet)
2. DOC_CHUNKS (chunk count, size distribution, sample chunks for each doc)
3. CHAT_HISTORY (recent user queries and AI responses)
4. Vector Retrieval Simulation for 'medical leave' and 'probationary period'
Outputs complete results to db_storage_analysis_output.txt
"""

import sys
import oracledb

oracledb.defaults.fetch_lobs = False

OUTPUT_FILE = "/home/ubuntu/docs/db_storage_analysis_output.txt"

def main():
    out = []
    def log(msg=""):
        print(msg)
        out.append(msg)

    log("=" * 80)
    log("ORACLE DATABASE 26ai RAG STORAGE DEEP DIAGNOSTIC")
    log("=" * 80)

    try:
        conn = oracledb.connect(
            user="AIDEMO",
            password="Apex_26ai_2026Free",
            dsn="20.0.1.130:1521/FREEPDB1"
        )
        cur = conn.cursor()
        log("Connected successfully to Oracle 26ai DB (AIDEMO@//20.0.1.130:1521/FREEPDB1)\n")

        # ---------------------------------------------------------------------
        # 1. SOURCE_DOCS Analysis
        # ---------------------------------------------------------------------
        log("--- 1. ACTIVE & INACTIVE SOURCE DOCUMENTS ---")
        cur.execute("""
            SELECT doc_id, title, status, version_no, file_size,
                   DBMS_LOB.GETLENGTH(content) as content_len,
                   ingested_at
            FROM source_docs
            ORDER BY doc_id ASC
        """)
        docs = cur.fetchall()
        for d in docs:
            doc_id, title, status, ver, f_size, c_len, ing_at = d
            log(f"Doc #{doc_id}: Title='{title}' | Status={status} | Ver={ver} | FileSize={f_size} | ContentLength={c_len} chars | Ingested={ing_at}")

        # ---------------------------------------------------------------------
        # 2. DOC_CHUNKS Analysis
        # ---------------------------------------------------------------------
        log("\n--- 2. CHUNKS PER DOCUMENT ---")
        cur.execute("""
            SELECT d.doc_id, d.title, COUNT(c.chunk_id) as total_chunks,
                   MIN(DBMS_LOB.GETLENGTH(c.chunk_text)) as min_len,
                   AVG(DBMS_LOB.GETLENGTH(c.chunk_text)) as avg_len,
                   MAX(DBMS_LOB.GETLENGTH(c.chunk_text)) as max_len
            FROM source_docs d
            LEFT JOIN doc_chunks c ON d.doc_id = c.doc_id
            GROUP BY d.doc_id, d.title
            ORDER BY d.doc_id ASC
        """)
        for ch_stat in cur.fetchall():
            doc_id, title, cnt, min_l, avg_l, max_l = ch_stat
            avg_str = f"{avg_l:.1f}" if avg_l is not None else "0"
            log(f"Doc #{doc_id} ('{title}'): Chunks={cnt} | Min={min_l} chars | Avg={avg_str} chars | Max={max_l} chars")

        # ---------------------------------------------------------------------
        # 3. Sample Chunks for Each Document
        # ---------------------------------------------------------------------
        log("\n--- 3. SAMPLE CHUNKS CONTENT (First 3 chunks per doc) ---")
        for d in docs:
            doc_id, title = d[0], d[1]
            log(f"\n>> Document #{doc_id} ('{title}') Samples:")
            cur.execute("""
                SELECT chunk_no, SUBSTR(chunk_text, 1, 350) as snippet, DBMS_LOB.GETLENGTH(chunk_text) as total_len
                FROM doc_chunks
                WHERE doc_id = :1
                ORDER BY chunk_no ASC
                FETCH FIRST 3 ROWS ONLY
            """, [doc_id])
            samples = cur.fetchall()
            if not samples:
                log("   (No chunks found in doc_chunks!)")
            for s in samples:
                c_no, snip, t_len = s
                clean_snip = snip.replace("\n", " ")[:200]
                log(f"   [Chunk #{c_no}] (Length: {t_len} chars): {clean_snip}...")

        # ---------------------------------------------------------------------
        # 4. CHAT_HISTORY Logs Analysis (Last 8 queries)
        # ---------------------------------------------------------------------
        log("\n--- 4. LATEST CHAT HISTORY QUERIES & AI RESPONSES ---")
        cur.execute("""
            SELECT msg_id, session_id, user_prompt, 
                   SUBSTR(ai_response, 1, 400) as resp_snip,
                   sources, response_time_ms, created_at
            FROM chat_history
            ORDER BY msg_id DESC
            FETCH FIRST 8 ROWS ONLY
        """)
        chats = cur.fetchall()
        for ch in chats:
            m_id, s_id, prompt, resp, src, lat, c_time = ch
            log(f"\n[Msg #{m_id}] Time={c_time} | Latency={lat}ms | Sources={src}")
            log(f"   User: {prompt}")
            resp_clean = resp.replace("\n", " ")[:300] if resp else "(EMPTY/NULL)"
            log(f"   AI:   {resp_clean}...")

        # ---------------------------------------------------------------------
        # 5. Vector Retrieval Diagnostic for 'medical leave'
        # ---------------------------------------------------------------------
        test_q = "What is the policy for medical leave and certificates?"
        log(f"\n--- 5. VECTOR SEARCH RETRIEVAL TEST FOR: '{test_q}' ---")
        cur.execute("""
            SELECT c.doc_id, d.title, c.chunk_no,
                   VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING :q AS DATA), COSINE) as dist,
                   SUBSTR(c.chunk_text, 1, 300) as snippet
            FROM doc_chunks c
            JOIN source_docs d ON c.doc_id = d.doc_id
            WHERE d.status = 'ACTIVE'
            ORDER BY dist ASC
            FETCH FIRST 5 ROWS ONLY
        """, [test_q])
        results = cur.fetchall()
        for r in results:
            doc_id, title, ch_no, dist, snippet = r
            sim = (1.0 - dist) * 100
            log(f"   Match: Doc #{doc_id} ('{title}') Chunk #{ch_no} | Distance: {dist:.4f} (Sim: {sim:.1f}%)")
            log(f"          Snippet: {snippet.replace(chr(10), ' ')[:200]}...")

        # ---------------------------------------------------------------------
        # 6. Check for Broken / Garbage Chunks in DB
        # ---------------------------------------------------------------------
        log("\n--- 6. CHUNK QUALITY & POTENTIAL STORAGE DEFECTS ---")
        # Check chunks with very low character count (< 40 chars)
        cur.execute("""
            SELECT COUNT(*) FROM doc_chunks WHERE DBMS_LOB.GETLENGTH(chunk_text) < 40
        """)
        short_cnt = cur.fetchone()[0]
        log(f"   Tiny/Garbage chunks (< 40 chars): {short_cnt}")

        # Check chunks with null embedding
        cur.execute("""
            SELECT COUNT(*) FROM doc_chunks WHERE embedding IS NULL
        """)
        null_emb = cur.fetchone()[0]
        log(f"   Chunks with NULL embedding: {null_emb}")

        # Check active docs without chunks
        cur.execute("""
            SELECT d.doc_id, d.title FROM source_docs d
            WHERE d.status = 'ACTIVE' AND NOT EXISTS (
                SELECT 1 FROM doc_chunks c WHERE c.doc_id = d.doc_id
            )
        """)
        orphan_docs = cur.fetchall()
        log(f"   Active docs with 0 chunks: {len(orphan_docs)}")
        for od in orphan_docs:
            log(f"     -> Doc #{od[0]}: '{od[1]}'")

        cur.close()
        conn.close()

    except Exception as e:
        log(f"\nERROR during diagnostic: {e}")
        import traceback
        log(traceback.format_exc())

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write("\n".join(out))
    print(f"\nDiagnostic written to {OUTPUT_FILE}")

if __name__ == "__main__":
    main()
