SET LINESIZE 300;
SET PAGESIZE 100;
ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

SELECT doc_id, title, status, file_size, mime_type, ingested_at
FROM source_docs
ORDER BY doc_id DESC;

SELECT chunk_id, doc_id, chunk_no, SUBSTR(chunk_text, 1, 120)
FROM doc_chunks
WHERE chunk_id IN (672, 673, 675)
ORDER BY chunk_id;

SELECT doc_id, chunk_no, SUBSTR(chunk_text, 1, 150)
FROM doc_chunks
WHERE doc_id = 161 AND (UPPER(chunk_text) LIKE '%PROBATION%' OR chunk_no <= 5)
ORDER BY chunk_no;

EXIT;
