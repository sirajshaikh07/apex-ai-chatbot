SET LINESIZE 250;
SET PAGESIZE 100;
SET SERVEROUTPUT ON;

ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

BEGIN
  DBMS_OUTPUT.PUT_LINE('=== CHUNKS CONTAINING SIRAJ AND COMPLETED/DONE ===');
  FOR r IN (
    SELECT c.doc_id, d.title, c.chunk_no, SUBSTR(c.chunk_text, 1, 300) as snippet
    FROM doc_chunks c
    JOIN source_docs d ON c.doc_id = d.doc_id
    WHERE UPPER(c.chunk_text) LIKE '%SIRAJ%'
    ORDER BY c.doc_id, c.chunk_no
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('Doc ' || r.doc_id || ' (' || r.title || ') Chunk ' || r.chunk_no || ': ' || r.snippet);
  END LOOP;
END;
/
EXIT;
