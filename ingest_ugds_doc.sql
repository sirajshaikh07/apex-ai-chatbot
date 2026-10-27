SET SERVEROUTPUT ON SIZE UNLIMITED;
SET DEFINE OFF;
ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

DECLARE
  l_doc_id   NUMBER;
  l_clob     CLOB;
  l_bfile    BFILE;
  l_chunks   NUMBER := 0;
BEGIN
  -- 1. Find the active document
  SELECT MAX(doc_id) INTO l_doc_id 
  FROM source_docs 
  WHERE status = 'ACTIVE';

  DBMS_OUTPUT.PUT_LINE('Target active doc_id: ' || l_doc_id);

  -- 2. Load the UGDS canonical text
  -- We read the file from disk using DBMS_LOB
  -- Or update directly via temporary CLOB
  DBMS_LOB.CREATETEMPORARY(l_clob, TRUE);
  
  -- Delete old chunks
  DELETE FROM doc_chunks WHERE doc_id = l_doc_id;
  DBMS_OUTPUT.PUT_LINE('Deleted old chunks for doc_id ' || l_doc_id);

END;
/
EXIT;
