ALTER TABLE source_docs ADD (file_hash VARCHAR2(64));
ALTER TABLE source_docs ADD (status VARCHAR2(20) DEFAULT 'ACTIVE' NOT NULL);
ALTER TABLE source_docs ADD (version_no NUMBER DEFAULT 1 NOT NULL);

set serveroutput on
DECLARE
  l_hash VARCHAR2(64);
BEGIN
  FOR d IN (SELECT doc_id, doc_blob FROM source_docs WHERE doc_blob IS NOT NULL) LOOP
    l_hash := RAWTOHEX(DBMS_CRYPTO.HASH(d.doc_blob, 2));
    UPDATE source_docs
    SET file_hash = l_hash,
        status = 'ACTIVE',
        version_no = 1
    WHERE doc_id = d.doc_id;
    dbms_output.put_line('Doc ID ' || d.doc_id || ' SHA-256: ' || SUBSTR(l_hash, 1, 16) || '...');
  END LOOP;
  COMMIT;
END;
/
exit;
