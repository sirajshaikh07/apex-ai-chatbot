
SET LINESIZE 250;
SELECT chunk_no, SUBSTR(chunk_text, 1, 300) 
FROM doc_chunks 
WHERE doc_id = (SELECT MAX(doc_id) FROM source_docs WHERE status = 'ACTIVE')
  AND UPPER(chunk_text) LIKE '%TASK 20%';
EXIT;
