set serveroutput on size unlimited feedback off linesize 200 pagesize 0 trimout on
DECLARE
  l_chunks NUMBER;
BEGIN
  FOR d IN (
    SELECT doc_id, title, source_ref, mime_type, doc_blob
    FROM source_docs
    ORDER BY doc_id
  ) LOOP
    dbms_output.put_line('----------------------------------------------------');
    dbms_output.put_line('Re-ingesting with 150-word chunking: ' || d.title || ' (Doc ID: ' || d.doc_id || ')');
    
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
