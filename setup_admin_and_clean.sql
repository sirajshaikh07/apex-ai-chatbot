set define off serveroutput on linesize 200 feedback on

PROMPT ========================================================
PROMPT   1. Clearing All Dummy/Fake Data & Embeddings
PROMPT ========================================================

DELETE FROM doc_chunks;
DELETE FROM source_docs;
DELETE FROM chat_history;
COMMIT;
PROMPT All dummy documents, chunks, embeddings, and chat history deleted successfully.

PROMPT ========================================================
PROMPT   2. Upgrading SOURCE_DOCS for Universal Document Uploads
PROMPT ========================================================

DECLARE
  v_col_exists NUMBER;
BEGIN
  SELECT count(*) INTO v_col_exists 
  FROM user_tab_columns 
  WHERE table_name = 'SOURCE_DOCS' AND column_name = 'DOC_BLOB';
  
  IF v_col_exists = 0 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE source_docs ADD (doc_blob BLOB, mime_type VARCHAR2(100), file_size NUMBER)';
    dbms_output.put_line('Added doc_blob, mime_type, file_size columns to source_docs.');
  ELSE
    dbms_output.put_line('Columns already present in source_docs.');
  END IF;
END;
/

PROMPT ========================================================
PROMPT   3. Creating USER_REGISTRATIONS Table for Approval Flow
PROMPT ========================================================

BEGIN
  EXECUTE IMMEDIATE '
    CREATE TABLE user_registrations (
        request_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        username       VARCHAR2(100) NOT NULL UNIQUE,
        full_name      VARCHAR2(255) NOT NULL,
        email          VARCHAR2(255) NOT NULL,
        password       VARCHAR2(255) NOT NULL,
        requested_at   TIMESTAMP DEFAULT SYSTIMESTAMP,
        status         VARCHAR2(20) DEFAULT ''PENDING'' CHECK (status IN (''PENDING'', ''APPROVED'', ''REJECTED'')),
        reviewed_by    VARCHAR2(100),
        reviewed_at    TIMESTAMP,
        notes          VARCHAR2(500)
    )
  ';
  dbms_output.put_line('Table user_registrations created.');
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE = -955 THEN
      dbms_output.put_line('Table user_registrations already exists.');
    ELSE
      RAISE;
    END IF;
END;
/

PROMPT ========================================================
PROMPT   4. Creating User Approval & Rejection Procedures
PROMPT ========================================================

CREATE OR REPLACE PROCEDURE approve_user_registration (
    p_request_id IN NUMBER,
    p_admin_user IN VARCHAR2
) AS
    l_user  VARCHAR2(100);
    l_pass  VARCHAR2(255);
    l_name  VARCHAR2(255);
    l_email VARCHAR2(255);
    l_first VARCHAR2(100);
    l_last  VARCHAR2(100);
    l_uid   NUMBER;
BEGIN
    SELECT username, password, full_name, email
    INTO   l_user, l_pass, l_name, l_email
    FROM   user_registrations
    WHERE  request_id = p_request_id;

    l_first := NVL(SUBSTR(l_name, 1, INSTR(l_name, ' ') - 1), l_name);
    l_last  := NVL(SUBSTR(l_name, INSTR(l_name, ' ') + 1), 'User');

    apex_util.set_workspace('AIDEMO');
    l_uid := apex_util.get_user_id(UPPER(l_user));
    IF l_uid IS NOT NULL THEN
        apex_util.remove_user(p_user_id => l_uid);
    END IF;

    apex_util.create_user(
        p_user_name                    => UPPER(l_user),
        p_first_name                   => l_first,
        p_last_name                    => l_last,
        p_email_address                => l_email,
        p_web_password                 => l_pass,
        p_change_password_on_first_use => 'N'
    );

    UPDATE user_registrations
    SET status = 'APPROVED', reviewed_by = p_admin_user, reviewed_at = SYSTIMESTAMP
    WHERE request_id = p_request_id;
    COMMIT;
END approve_user_registration;
/

CREATE OR REPLACE PROCEDURE reject_user_registration (
    p_request_id IN NUMBER,
    p_admin_user IN VARCHAR2
) AS
BEGIN
    UPDATE user_registrations
    SET status = 'REJECTED', reviewed_by = p_admin_user, reviewed_at = SYSTIMESTAMP
    WHERE request_id = p_request_id;
    COMMIT;
END reject_user_registration;
/

PROMPT ========================================================
PROMPT   5. Universal Document Ingestion Procedure (Any File Type)
PROMPT ========================================================

CREATE OR REPLACE PROCEDURE ingest_file_document (
  p_file_name    IN  VARCHAR2,
  p_title        IN  VARCHAR2 DEFAULT NULL,
  p_chunks_count OUT NUMBER
) AS
  l_blob         BLOB;
  l_clob         CLOB;
  l_mime         VARCHAR2(255);
  l_filename     VARCHAR2(500);
  l_title        VARCHAR2(500);
  l_doc_id       NUMBER;
BEGIN
  -- 1. Locate file in APEX temporary files
  BEGIN
    SELECT filename, mime_type, blob_content 
    INTO   l_filename, l_mime, l_blob
    FROM   apex_application_temp_files
    WHERE  name = p_file_name;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20001, 'Uploaded file not found in temporary storage: ' || p_file_name);
  END;

  l_title := NVL(TRIM(p_title), l_filename);

  -- 2. Multi-Engine Text Extraction (Supports PDF, DOCX, DOC, XLSX, XLS, PPTX, PPT, TXT, CSV, MD, JSON, XML, HTML, LOG, RTF, etc.)
  -- Step 2a: Try Oracle 26ai Native Document Filtering Engine (for rich documents like PDF, Word, Excel, PowerPoint)
  BEGIN
    l_clob := DBMS_VECTOR_CHAIN.UTL_TO_TEXT(l_blob);
  EXCEPTION
    WHEN OTHERS THEN
      l_clob := NULL;
  END;

  -- Step 2b: If empty or failed, try APEX UTF-8 BLOB to CLOB converter (for text, markdown, csv, json, xml, code)
  IF l_clob IS NULL OR LENGTH(TRIM(l_clob)) = 0 THEN
    BEGIN
      l_clob := APEX_UTIL.BLOB_TO_CLOB(l_blob);
    EXCEPTION
      WHEN OTHERS THEN
        l_clob := NULL;
    END;
  END IF;

  -- Step 2c: If still empty, try DBMS_LOB.CONVERTTOCLOB
  IF l_clob IS NULL OR LENGTH(TRIM(l_clob)) = 0 THEN
    DECLARE
      l_dest_offset INTEGER := 1;
      l_src_offset  INTEGER := 1;
      l_lang_ctx    INTEGER := DBMS_LOB.DEFAULT_LANG_CTX;
      l_warning     INTEGER;
    BEGIN
      DBMS_LOB.CREATETEMPORARY(l_clob, TRUE);
      DBMS_LOB.CONVERTTOCLOB(
        l_clob,
        l_blob,
        DBMS_LOB.LOBMAXSIZE,
        l_dest_offset,
        l_src_offset,
        DBMS_LOB.DEFAULT_CSID,
        l_lang_ctx,
        l_warning
      );
    EXCEPTION
      WHEN OTHERS THEN
        l_clob := NULL;
    END;
  END IF;

  -- Step 2d: Sanitize extracted text: strip null bytes and normalize whitespace
  IF l_clob IS NOT NULL THEN
    l_clob := REPLACE(l_clob, CHR(0), ' ');
  END IF;

  IF l_clob IS NULL OR LENGTH(TRIM(l_clob)) = 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'Could not extract text from document: ' || l_filename);
  END IF;

  -- 3. Ingest into SOURCE_DOCS
  MERGE INTO source_docs d
  USING (SELECT l_title AS title, l_filename AS source_ref, l_clob AS content, l_blob AS doc_blob, l_mime AS mime_type, DBMS_LOB.GETLENGTH(l_blob) AS file_size FROM dual) s
  ON (d.title = s.title)
  WHEN MATCHED THEN
    UPDATE SET content = s.content, source_ref = s.source_ref, doc_blob = s.doc_blob, mime_type = s.mime_type, file_size = s.file_size, ingested_at = NULL
  WHEN NOT MATCHED THEN
    INSERT (title, source_ref, content, doc_blob, mime_type, file_size) 
    VALUES (s.title, s.source_ref, s.content, s.doc_blob, s.mime_type, s.file_size);

  SELECT doc_id INTO l_doc_id FROM source_docs WHERE title = l_title;

  -- 4. Delete old chunks if updating
  DELETE FROM doc_chunks WHERE doc_id = l_doc_id;

  -- 5. Auto-chunk and generate 384-dimensional vector embeddings
  INSERT INTO doc_chunks (doc_id, chunk_no, chunk_text, embedding)
  SELECT d.doc_id, 
         ROW_NUMBER() OVER (PARTITION BY d.doc_id ORDER BY c.chunk_offset),
         c.chunk_text,
         VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING c.chunk_text AS data)
  FROM   source_docs d,
         VECTOR_CHUNKS(d.content BY words MAX 150 OVERLAP 15
                       SPLIT BY recursively LANGUAGE american NORMALIZE all) c
  WHERE  d.doc_id = l_doc_id;

  SELECT count(*) INTO p_chunks_count FROM doc_chunks WHERE doc_id = l_doc_id;

  UPDATE source_docs SET ingested_at = SYSTIMESTAMP WHERE doc_id = l_doc_id;
  COMMIT;
END ingest_file_document;
/

CREATE OR REPLACE PROCEDURE delete_document (
  p_doc_id IN NUMBER
) AS
BEGIN
  DELETE FROM doc_chunks WHERE doc_id = p_doc_id;
  DELETE FROM source_docs WHERE doc_id = p_doc_id;
  COMMIT;
END delete_document;
/

PROMPT ========================================================
PROMPT   6. Ensuring Admin User SIRAJ / siraj Exists
PROMPT ========================================================

DECLARE
  l_uid NUMBER;
BEGIN
  apex_util.set_workspace('AIDEMO');
  l_uid := apex_util.get_user_id('SIRAJ');
  IF l_uid IS NOT NULL THEN
    apex_util.remove_user(p_user_id => l_uid);
  END IF;

  apex_util.create_user(
    p_user_name                    => 'SIRAJ',
    p_first_name                   => 'Siraj',
    p_last_name                    => 'Admin',
    p_email_address                => 'siraj@example.com',
    p_web_password                 => 'siraj',
    p_developer_privs              => 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
    p_change_password_on_first_use => 'N'
  );
  dbms_output.put_line('User SIRAJ created with password siraj and Administrator role.');
  COMMIT;
END;
/

PROMPT ========================================================
PROMPT   7. Verifying Clean Database State
PROMPT ========================================================

SELECT count(*) as remaining_docs FROM source_docs;
SELECT count(*) as remaining_chunks FROM doc_chunks;
SELECT count(*) as remaining_chat FROM chat_history;

exit;
