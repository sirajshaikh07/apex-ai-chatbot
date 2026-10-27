SET LINESIZE 300;
SET PAGESIZE 100;
SET SERVEROUTPUT ON SIZE UNLIMITED;
ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

PROMPT ============================================================
PROMPT 1. CHECK CHUNKS IN DOC 161 WITH 'PROBATION'
PROMPT ============================================================
SELECT chunk_id, doc_id, chunk_no, LENGTH(chunk_text) as len, SUBSTR(chunk_text, 1, 200) as snippet
FROM doc_chunks
WHERE doc_id = 161 AND UPPER(chunk_text) LIKE '%PROBATION%'
ORDER BY chunk_no;

PROMPT ============================================================
PROMPT 2. VECTOR SEARCH DISTANCE FOR THE QUERY
PROMPT ============================================================
SELECT c.chunk_id, c.doc_id, d.title, c.chunk_no,
       ROUND(VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING 'How long is the probationary period for new appointments, and by how much can it be extended?' AS data), COSINE), 4) as vec_dist
FROM doc_chunks c
JOIN source_docs d ON c.doc_id = d.doc_id
WHERE d.status = 'ACTIVE'
ORDER BY vec_dist ASC
FETCH FIRST 10 ROWS ONLY;

PROMPT ============================================================
PROMPT 3. CHECK WHAT RESOLVE_QUERY DOES FOR THIS QUESTION
PROMPT ============================================================
DECLARE
  l_resolved VARCHAR2(4000);
  l_proj VARCHAR2(50);
  l_user VARCHAR2(100);
  l_cnt  BOOLEAN;
BEGIN
  -- We test how resolve_hinglish processes this
  DBMS_OUTPUT.PUT_LINE('resolve_hinglish output: ' || enterprise_rag_pkg.resolve_hinglish('How long is the probationary period for new appointments, and by how much can it be extended?'));
END;
/

EXIT;
