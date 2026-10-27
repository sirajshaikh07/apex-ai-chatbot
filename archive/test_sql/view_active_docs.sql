SET SERVEROUTPUT ON SIZE UNLIMITED;
SET LINESIZE 250;
ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

BEGIN
  FOR d IN (SELECT doc_id, title, status, DBMS_LOB.GETLENGTH(content) as clen FROM source_docs WHERE status = 'ACTIVE') LOOP
    DBMS_OUTPUT.PUT_LINE('DOC ID: ' || d.doc_id || ' | TITLE: ' || d.title || ' | LEN: ' || d.clen);
  END LOOP;
END;
/
EXIT;
