SET LINESIZE 300;
SET PAGESIZE 500;
SET SERVEROUTPUT ON SIZE UNLIMITED;

ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

BEGIN
  FOR r IN (
    SELECT c.chunk_no, c.chunk_text
    FROM doc_chunks c
    JOIN source_docs d ON c.doc_id = d.doc_id
    WHERE d.status = 'ACTIVE'
      AND UPPER(c.chunk_text) LIKE '%SIRAJ%'
    ORDER BY c.chunk_no
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('=== CHUNK #' || r.chunk_no || ' (Length: ' || LENGTH(r.chunk_text) || ') ===');
    DBMS_OUTPUT.PUT_LINE(r.chunk_text);
  END LOOP;
END;
/
EXIT;
