SET SERVEROUTPUT ON SIZE UNLIMITED;
SET LINESIZE 250;
ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

BEGIN
  DBMS_OUTPUT.PUT_LINE('========================================================');
  DBMS_OUTPUT.PUT_LINE('1. ACTIVE DOCUMENTS IN SOURCE_DOCS');
  DBMS_OUTPUT.PUT_LINE('========================================================');
  FOR d IN (SELECT doc_id, title, status, DBMS_LOB.GETLENGTH(content) as clen FROM source_docs WHERE status = 'ACTIVE') LOOP
    DECLARE
      l_chunks NUMBER := 0;
      l_siraj_chunks NUMBER := 0;
    BEGIN
      SELECT count(*) INTO l_chunks FROM doc_chunks WHERE doc_id = d.doc_id;
      SELECT count(*) INTO l_siraj_chunks FROM doc_chunks WHERE doc_id = d.doc_id AND UPPER(chunk_text) LIKE '%SIRAJ%';
      DBMS_OUTPUT.PUT_LINE('DOC ID ' || d.doc_id || ': ' || d.title || ' | Length: ' || d.clen || ' chars | Total Chunks: ' || l_chunks || ' | Chunks with Siraj: ' || l_siraj_chunks);
    END;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE(CHR(10) || '========================================================');
  DBMS_OUTPUT.PUT_LINE('2. TASKS MENTIONING SIRAJ IN EACH ACTIVE DOCUMENT');
  DBMS_OUTPUT.PUT_LINE('========================================================');
  FOR c IN (
    SELECT d.title, c.chunk_no, SUBSTR(c.chunk_text, 1, 200) as snippet
    FROM doc_chunks c
    JOIN source_docs d ON c.doc_id = d.doc_id
    WHERE d.status = 'ACTIVE'
      AND UPPER(c.chunk_text) LIKE '%SIRAJ%'
    ORDER BY d.doc_id, c.chunk_no
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('[' || c.title || ' - Chunk ' || c.chunk_no || ']: ' || c.snippet);
  END LOOP;
END;
/
EXIT;
