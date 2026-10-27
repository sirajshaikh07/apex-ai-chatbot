SET LINESIZE 250;
SET PAGESIZE 100;
SET SERVEROUTPUT ON SIZE UNLIMITED;

ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

BEGIN
  DBMS_OUTPUT.PUT_LINE('=== PROJECTS IN ALL_APP_DATA_CLEAN.TXT ===');
  FOR r IN (
    SELECT chunk_no, chunk_text
    FROM doc_chunks c
    JOIN source_docs d ON c.doc_id = d.doc_id
    WHERE d.status = 'ACTIVE'
      AND UPPER(c.chunk_text) LIKE '%PROJECT:%'
    ORDER BY c.chunk_no
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('Chunk ' || r.chunk_no || ': ' || SUBSTR(r.chunk_text, 1, 150));
  END LOOP;
END;
/
EXIT;
