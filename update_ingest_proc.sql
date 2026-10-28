-- ==============================================================================
-- Upgraded INGEST_DOCUMENT_BLOB & INGEST_FILE_DOCUMENT (Tier 1 Production Grade)
-- 1. Contextual Headers: Embeds '[Document: <title>]' into chunk text & vector
-- 2. Duplicate Detection: SHA-256 Hash check prevents duplicate file uploads
-- 3. Document Lifecycle: Sets status = 'ACTIVE', versioning & file_hash
-- Oracle AI Database 26ai Free (23.26.3) + Tesseract 5.3 + poppler OCR Service
-- ==============================================================================
SET DEFINE OFF SERVEROUTPUT ON FEEDBACK ON;

CREATE OR REPLACE PROCEDURE ingest_document_blob (
  p_filename     IN  VARCHAR2,
  p_blob         IN  BLOB,
  p_mime         IN  VARCHAR2 DEFAULT 'application/octet-stream',
  p_title        IN  VARCHAR2 DEFAULT NULL,
  p_chunks_count OUT NUMBER
) AS
  l_clob         CLOB;
  l_title        VARCHAR2(500);
  l_doc_id       NUMBER;
  l_file_hash    VARCHAR2(64);
  l_existing_id  NUMBER;
  l_existing_tit VARCHAR2(500);
  l_resp         CLOB;
  l_ocr_status   VARCHAR2(50);
  l_ocr_text     CLOB;
BEGIN
  l_title := NVL(TRIM(p_title), p_filename);

  -- 1. Compute SHA-256 Hash for Duplicate Detection (Item 15)
  IF p_blob IS NOT NULL AND DBMS_LOB.GETLENGTH(p_blob) > 0 THEN
    l_file_hash := RAWTOHEX(DBMS_CRYPTO.HASH(p_blob, 2)); -- 2 = HASH_SH256
    
    -- Check if identical active file already exists under a different title
    BEGIN
      SELECT doc_id, title INTO l_existing_id, l_existing_tit
      FROM source_docs
      WHERE file_hash = l_file_hash AND status = 'ACTIVE' AND title != l_title
      FETCH FIRST 1 ROWS ONLY;

      RAISE_APPLICATION_ERROR(-20002, 'Duplicate upload prevented: An identical document already exists in the knowledge base as #' || l_existing_id || ' (' || l_existing_tit || ').');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
  END IF;

  -- 2. Multi-Engine Text Extraction
  -- Step 2a: Try Oracle 26ai Native Document Filtering Engine (for digital PDF, Word, Excel)
  BEGIN
    l_clob := DBMS_VECTOR_CHAIN.UTL_TO_TEXT(p_blob);
  EXCEPTION
    WHEN OTHERS THEN
      l_clob := NULL;
  END;

  -- Step 2b: If empty or failed, try APEX UTF-8 BLOB to CLOB converter (for text, markdown, csv)
  IF l_clob IS NULL OR LENGTH(TRIM(l_clob)) = 0 THEN
    BEGIN
      l_clob := APEX_UTIL.BLOB_TO_CLOB(p_blob);
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
        p_blob,
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

  -- Step 2d: Sanitize extracted text: strip null bytes and normalize control chars
  IF l_clob IS NOT NULL THEN
    l_clob := REPLACE(l_clob, CHR(0), ' ');
    l_clob := REGEXP_REPLACE(l_clob, '[[:cntrl:]&&[^'||CHR(10)||CHR(13)||CHR(9)||']]', ' ');
  END IF;

  -- Step 2e: OCR Fallback Microservice for Scanned Documents & Images
  IF l_clob IS NULL OR LENGTH(TRIM(l_clob)) < 40 THEN
    BEGIN
      apex_web_service.set_request_headers(
        p_name_01  => 'Content-Type',
        p_value_01 => NVL(p_mime, 'application/octet-stream'),
        p_reset    => TRUE
      );

      BEGIN
        l_resp := apex_web_service.make_rest_request(
          p_url         => 'http://20.0.1.39:5055/ocr?filename=' || apex_util.url_encode(p_filename),
          p_http_method => 'POST',
          p_body_blob   => p_blob
        );

        l_ocr_status := JSON_VALUE(l_resp, '$.status');
        IF l_ocr_status = 'SUCCESS' THEN
          l_ocr_text := JSON_VALUE(l_resp, '$.text');
          IF l_ocr_text IS NOT NULL AND LENGTH(TRIM(l_ocr_text)) > 0 THEN
            l_clob := l_ocr_text;
          END IF;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;
  END IF;

  -- Verify extraction resulted in usable text
  IF l_clob IS NULL OR LENGTH(TRIM(l_clob)) = 0 THEN
    RAISE_APPLICATION_ERROR(-20003, 'Could not extract text from document: ' || p_filename || '. (Empty file or unreadable scan).');
  END IF;

  -- 3. Ingest into SOURCE_DOCS with SHA-256 Hash and Status (Item 4 & 15)
  MERGE INTO source_docs d
  USING (SELECT l_title AS title, p_filename AS source_ref, l_clob AS content, p_blob AS doc_blob, p_mime AS mime_type, DBMS_LOB.GETLENGTH(p_blob) AS file_size, l_file_hash AS file_hash FROM dual) s
  ON (d.title = s.title)
  WHEN MATCHED THEN
    UPDATE SET content = s.content, source_ref = s.source_ref, doc_blob = s.doc_blob, mime_type = s.mime_type, file_size = s.file_size, file_hash = s.file_hash, status = 'ACTIVE', version_no = d.version_no + 1, ingested_at = NULL
  WHEN NOT MATCHED THEN
    INSERT (title, source_ref, content, doc_blob, mime_type, file_size, file_hash, status, version_no) 
    VALUES (s.title, s.source_ref, s.content, s.doc_blob, s.mime_type, s.file_size, s.file_hash, 'ACTIVE', 1);

  SELECT doc_id INTO l_doc_id FROM source_docs WHERE title = l_title;

  -- 4. Delete old chunks if updating document
  DELETE FROM doc_chunks WHERE doc_id = l_doc_id;

  -- 5. Universal Hierarchical Context Header Injection & Semantic Chunking (Fix 1 Enterprise Standard)
  -- Automatically tracks active section headers across chunk boundaries so that sub-chunks,
  -- procedures, multi-stage policies, and roll-over pages inherit the parent section context!
  DECLARE
    l_chunk_no        NUMBER := 0;
    l_curr_section    VARCHAR2(300) := NULL;
    l_header_match    VARCHAR2(300);
    l_full_chunk_text CLOB;
  BEGIN
    FOR rec IN (
      SELECT c.chunk_offset, c.chunk_text
      FROM   source_docs d,
             VECTOR_CHUNKS(d.content BY characters MAX 1200 OVERLAP 100
                           SPLIT CUSTOM ('---', '# ', '## ', '### ')
                           LANGUAGE american NORMALIZE all) c
      WHERE  d.doc_id = l_doc_id
      ORDER BY c.chunk_offset ASC
    ) LOOP
      l_chunk_no := l_chunk_no + 1;
      
      -- Extract section title if present in this chunk:
      -- Matches: # Heading, ## Heading, ### Heading, or [SECTION: ...], or Section X: ...
      l_header_match := REGEXP_SUBSTR(rec.chunk_text, '(#{1,3}\s*\[?SECTION:?[^]\r\n]+\]?|#{1,3}\s*[^#\r\n]{3,80}|Section\s+\d+[^:\r\n]{0,60}|^\s*\d+\.\s+[A-Z][A-Za-z0-9 ]{3,60})', 1, 1, 'm');
      
      IF l_header_match IS NOT NULL THEN
        -- Clean markdown formatting marks from heading
        l_curr_section := TRIM(REGEXP_REPLACE(l_header_match, '^(#{1,3}\s*|\[SECTION:\s*|\[|\])', ''));
        l_curr_section := TRIM(REGEXP_REPLACE(l_curr_section, '\]$', ''));
        IF LENGTH(l_curr_section) > 120 THEN
          l_curr_section := SUBSTR(l_curr_section, 1, 120);
        END IF;
      END IF;

      -- Formulate canonical contextualized chunk text:
      -- e.g. [Document: Employee Handbook | Section: 6. Controlling Absence Policy] Stage 2...
      l_full_chunk_text := '[Document: ' || l_title || 
                           CASE WHEN l_curr_section IS NOT NULL THEN ' | Section: ' || l_curr_section END || 
                           '] ' || rec.chunk_text;

      INSERT INTO doc_chunks (doc_id, chunk_no, chunk_text, embedding, project_code, keywords)
      VALUES (
        l_doc_id,
        l_chunk_no,
        l_full_chunk_text,
        VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING l_full_chunk_text AS DATA),
        NULL,
        NULL
      );
    END LOOP;
  END;

  SELECT count(*) INTO p_chunks_count FROM doc_chunks WHERE doc_id = l_doc_id;

  UPDATE source_docs SET ingested_at = SYSTIMESTAMP WHERE doc_id = l_doc_id;
  COMMIT;
END ingest_document_blob;
/

CREATE OR REPLACE PROCEDURE ingest_file_document (
  p_file_name    IN  VARCHAR2,
  p_title        IN  VARCHAR2 DEFAULT NULL,
  p_chunks_count OUT NUMBER
) AS
  l_blob         BLOB;
  l_mime         VARCHAR2(255);
  l_filename     VARCHAR2(500);
BEGIN
  -- Locate file in APEX temporary files
  BEGIN
    SELECT filename, mime_type, blob_content 
    INTO   l_filename, l_mime, l_blob
    FROM   apex_application_temp_files
    WHERE  name = p_file_name;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20001, 'Uploaded file not found in temporary storage: ' || p_file_name);
  END;

  ingest_document_blob(
    p_filename     => l_filename,
    p_blob         => l_blob,
    p_mime         => l_mime,
    p_title        => p_title,
    p_chunks_count => p_chunks_count
  );
END ingest_file_document;
/
exit;
