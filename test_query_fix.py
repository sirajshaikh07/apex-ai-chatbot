#!/usr/bin/env python3
import oracledb

conn = oracledb.connect(user="AIDEMO", password="Apex_26ai_2026Free", dsn="20.0.1.130:1521/FREEPDB1")
cursor = conn.cursor()

plsql = """
DECLARE
    l_question   VARCHAR2(4000) := :1;
    l_session_id NUMBER := :2;
    l_user_name  VARCHAR2(100) := :3;
    l_prompt     CLOB;
    l_sources    VARCHAR2(1000);
    l_is_cache   VARCHAR2(1) := 'N';
    l_cached_ans CLOB;
    l_cached_msg NUMBER := 0;
    
    l_clean_q    VARCHAR2(4000);
    l_embedding  VECTOR;
    l_chunks_ctx CLOB;
BEGIN
    l_clean_q := REGEXP_REPLACE(l_question, '^([Qq][0-9]+|[0-9]+)\s*[:\.\)]\s*', '');
    SELECT VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING l_clean_q AS DATA) INTO l_embedding FROM dual;

    DBMS_LOB.CREATETEMPORARY(l_chunks_ctx, TRUE);
    
    FOR c IN (
        WITH vec_cand AS (
            SELECT c.chunk_id, c.doc_id, c.chunk_no, c.chunk_text,
                   VECTOR_DISTANCE(c.embedding, l_embedding, COSINE) AS dist
            FROM doc_chunks c
            JOIN source_docs d ON c.doc_id = d.doc_id
            WHERE d.status = 'ACTIVE'
            ORDER BY dist ASC
            FETCH FIRST 20 ROWS ONLY
        ),
        scored_cand AS (
            SELECT v.chunk_id, v.doc_id, v.chunk_no, v.chunk_text,
                   (v.dist - CASE 
                               WHEN UPPER(v.chunk_text) LIKE '%' || UPPER(l_clean_q) || '%' THEN 0.10
                               ELSE 0.0
                             END) AS adj_dist
            FROM vec_cand v
        ),
        top_cand AS (
            SELECT * FROM (
                SELECT * FROM scored_cand ORDER BY adj_dist ASC
            ) WHERE ROWNUM <= 2
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
        FETCH FIRST 3 ROWS ONLY
    ) LOOP
        DBMS_LOB.APPEND(l_chunks_ctx, TO_CLOB(CHR(10) || '--- [Document: ' || c.doc_title || ' | Chunk #' || c.chunk_no || '] ---' || CHR(10)));
        DBMS_LOB.APPEND(l_chunks_ctx, c.chunk_text);
        
        IF l_sources IS NULL THEN
            l_sources := c.doc_title;
        ELSIF INSTR(l_sources, c.doc_title) = 0 THEN
            l_sources := l_sources || ', ' || c.doc_title;
        END IF;
    END LOOP;

    DBMS_LOB.CREATETEMPORARY(l_prompt, TRUE);
    DBMS_LOB.APPEND(l_prompt, TO_CLOB('You are an authoritative Enterprise AI Assistant for Oracle APEX.' || CHR(10) || CHR(10)));
    DBMS_LOB.APPEND(l_prompt, TO_CLOB('ENTERPRISE CONTEXT CHUNKS:' || CHR(10)));
    DBMS_LOB.APPEND(l_prompt, l_chunks_ctx);
    DBMS_LOB.APPEND(l_prompt, TO_CLOB(CHR(10) || CHR(10) || 'USER QUESTION: ' || l_question || CHR(10) || 'ENTERPRISE AI ANSWER:'));

    :4 := 'N';
    :5 := l_prompt;
    :6 := NVL(l_sources, 'Enterprise Knowledge Base');
    :7 := 0;
END;
"""

out_is_cache = cursor.var(oracledb.DB_TYPE_VARCHAR)
out_prompt = cursor.var(oracledb.DB_TYPE_CLOB)
out_sources = cursor.var(oracledb.DB_TYPE_VARCHAR)
out_msg_id = cursor.var(oracledb.DB_TYPE_NUMBER)

cursor.execute(plsql, [
    "What is the policy for medical leave and certificates?",
    123,
    "TEST",
    out_is_cache,
    out_prompt,
    out_sources,
    out_msg_id
])

print("PL/SQL SUCCESS!")
print("Sources:", out_sources.getvalue())
val = out_prompt.getvalue()
print("Prompt Length:", len(val.read() if hasattr(val, 'read') else str(val)))
cursor.close()
conn.close()
