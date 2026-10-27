set heading on feedback off linesize 200 pagesize 50
SELECT doc_id, title, source_ref, file_size, ingested_at FROM source_docs;
SELECT doc_id, count(*) as chunk_count FROM doc_chunks GROUP BY doc_id;
exit;
