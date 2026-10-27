SET SERVEROUTPUT ON SIZE UNLIMITED;
SET LINESIZE 250;
ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

BEGIN
  DBMS_OUTPUT.PUT_LINE('=== CHUNKS MENTIONING YOGITA IN ACTIVE DOCS ===');
  FOR r IN (
    SELECT c.chunk_no, c.chunk_text
    FROM doc_chunks c
    JOIN source_docs d ON c.doc_id = d.doc_id
    WHERE d.status = 'ACTIVE'
      AND UPPER(c.chunk_text) LIKE '%YOGITA%'
    ORDER BY c.chunk_no
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('--- CHUNK ' || r.chunk_no || ' ---');
    DBMS_OUTPUT.PUT_LINE(SUBSTR(r.chunk_text, 1, 300));
  END LOOP;
END;
/
EXIT;
