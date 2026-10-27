SET LINESIZE 300;
SET PAGESIZE 100;
SET SERVEROUTPUT ON SIZE UNLIMITED;
ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

SELECT chunk_no, LENGTH(chunk_text) as len, SUBSTR(chunk_text, 1, 200) as snippet
FROM doc_chunks
WHERE doc_id = (SELECT MAX(doc_id) FROM source_docs WHERE status = 'ACTIVE')
  AND UPPER(chunk_text) LIKE '%SIRAJ%'
ORDER BY chunk_no;

EXIT;
