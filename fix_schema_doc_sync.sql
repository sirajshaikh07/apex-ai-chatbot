SET SERVEROUTPUT ON SIZE UNLIMITED;
SET LINESIZE 250;
ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

BEGIN
  DBMS_OUTPUT.PUT_LINE('=== SYNCING ENTERPRISE_PROJECTS TO ACTIVE SOURCE DOC ===');
  
  -- Link all projects to currently active document
  UPDATE enterprise_projects 
  SET source_doc_id = (SELECT doc_id FROM source_docs WHERE status = 'ACTIVE' FETCH FIRST 1 ROWS ONLY),
      updated_at = SYSTIMESTAMP;

  DBMS_OUTPUT.PUT_LINE('Updated ' || SQL%ROWCOUNT || ' enterprise_projects to active source_doc_id.');
  COMMIT;
END;
/
EXIT;
