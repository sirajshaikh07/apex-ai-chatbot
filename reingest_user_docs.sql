set serveroutput on size unlimited feedback off linesize 200 pagesize 0 trimout on
DECLARE
  l_chunks NUMBER;
BEGIN
  FOR d IN (
    SELECT doc_id, title, source_ref, mime_type, doc_blob
    FROM source_docs
    WHERE doc_id IN (121, 122)
  ) LOOP
    dbms_output.put_line('----------------------------------------------------');
    dbms_output.put_line('Processing with OCR: ' || d.title || ' (MIME: ' || d.mime_type || ')');
    
    BEGIN
      ingest_document_blob(
        p_filename     => d.source_ref,
        p_blob         => d.doc_blob,
        p_mime         => d.mime_type,
        p_title        => d.title,
        p_chunks_count => l_chunks
      );
      dbms_output.put_line('SUCCESS! Chunks created: ' || l_chunks);
    EXCEPTION
      WHEN OTHERS THEN
        dbms_output.put_line('ERROR: ' || SQLERRM);
    END;
  END LOOP;
END;
/
exit;
