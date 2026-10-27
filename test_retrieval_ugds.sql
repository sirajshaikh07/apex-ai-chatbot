SET SERVEROUTPUT ON SIZE UNLIMITED;
SET DEFINE OFF;
ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

DECLARE
  l_ans   CLOB;
  l_src   VARCHAR2(1000);
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== RETRIEVAL TEST FOR: Any pending task of siraj ===');
  
  -- Inspect the retrieved chunks and scores from the RAG package
  FOR r IN (
    SELECT c.chunk_no, c.chunk_text
    FROM doc_chunks c
    JOIN source_docs d ON c.doc_id = d.doc_id
    WHERE d.status = 'ACTIVE'
      AND UPPER(c.chunk_text) LIKE '%SIRAJ%'
      AND (UPPER(c.chunk_text) LIKE '%NOT STARTED%' OR UPPER(c.chunk_text) LIKE '%IN PROGRESS%')
    ORDER BY c.chunk_no
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('----------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Chunk ' || r.chunk_no || ':');
    DBMS_OUTPUT.PUT_LINE(SUBSTR(r.chunk_text, 1, 300));
  END LOOP;
END;
/
EXIT;
