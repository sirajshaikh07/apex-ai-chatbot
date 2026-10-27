SELECT chunk_id, doc_id, chunk_no, DBMS_LOB.SUBSTR(chunk_text, 80, 1) as txt 
FROM doc_chunks 
WHERE doc_id = 122;
exit;
