set heading on feedback off linesize 150 pagesize 50
SELECT d.doc_id, d.title, c.chunk_no, DBMS_LOB.SUBSTR(c.chunk_text, 120, 1) as preview 
FROM source_docs d
JOIN doc_chunks c ON d.doc_id = c.doc_id
ORDER BY d.doc_id, c.chunk_no;
exit;
