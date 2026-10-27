SET SERVEROUTPUT ON SIZE UNLIMITED;
SET LINESIZE 250;
ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

BEGIN
  FOR c IN (
    SELECT c.chunk_no, c.chunk_text
    FROM doc_chunks c
    JOIN source_docs d ON c.doc_id = d.doc_id
    WHERE d.status = 'ACTIVE'
      AND c.chunk_no IN (5, 6, 8, 10, 13, 16, 72, 115, 116)
    ORDER BY c.chunk_no
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('================ CHUNK ' || c.chunk_no || ' ================');
    DBMS_OUTPUT.PUT_LINE(c.chunk_text);
  END LOOP;
END;
/
EXIT;
