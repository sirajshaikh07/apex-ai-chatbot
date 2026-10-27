SET SERVEROUTPUT ON SIZE UNLIMITED;
SET DEFINE OFF;
ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

DECLARE
  p_raw VARCHAR2(1000) := 'Q1: How long is the probationary period for new appointments, and by how much can it be extended?';
  l_clean_prompt VARCHAR2(1000);
  l_search_q VARCHAR2(1000);
BEGIN
  -- Strip question prefix like 'Q1:', 'Q2:', '1.'
  l_clean_prompt := REGEXP_REPLACE(p_raw, '^(Q\d+[:.]?|Question\s*\d*[:.]?|\d+[\).])\s*', '', 1, 1, 'i');
  DBMS_OUTPUT.PUT_LINE('Cleaned prompt: ' || l_clean_prompt);

  DBMS_OUTPUT.PUT_LINE('--- TOP 5 BY PURE VECTOR DISTANCE ---');
  FOR r IN (
    SELECT c.doc_id, d.title, c.chunk_no,
           ROUND(VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING l_clean_prompt AS data), COSINE), 4) as dist
    FROM   source_docs d
    JOIN   doc_chunks c ON d.doc_id = c.doc_id
    WHERE  d.status = 'ACTIVE'
    ORDER BY dist ASC
    FETCH FIRST 5 ROWS ONLY
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('Doc=' || r.title || ' Chunk=' || r.chunk_no || ' Dist=' || r.dist);
  END LOOP;
END;
/
EXIT;
