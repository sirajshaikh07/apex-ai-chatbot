SET SERVEROUTPUT ON SIZE UNLIMITED;
SET LINESIZE 250;
ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

BEGIN
  DBMS_OUTPUT.PUT_LINE('=== ALL CHUNKS IN all_app_data_clean.txt MENTIONING SIRAJ ===');
  FOR c IN (
    SELECT c.chunk_no, c.chunk_text
    FROM doc_chunks c
    JOIN source_docs d ON c.doc_id = d.doc_id
    WHERE UPPER(d.title) LIKE '%CLEAN%'
      AND UPPER(c.chunk_text) LIKE '%SIRAJ%'
    ORDER BY c.chunk_no
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('--- Chunk ' || c.chunk_no || ' ---');
    DBMS_OUTPUT.PUT_LINE(SUBSTR(c.chunk_text, 1, 300));
  END LOOP;
END;
/
EXIT;
