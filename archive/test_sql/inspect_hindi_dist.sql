set serveroutput on size unlimited feedback off linesize 200 pagesize 0 trimout on
SELECT c.chunk_no, d.title, ROUND(VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING 'Aaj ka mausam kaisa hai?' AS data), COSINE), 4) as dist,
       DBMS_LOB.SUBSTR(c.chunk_text, 120, 1) as txt
FROM   source_docs d
JOIN   doc_chunks c ON d.doc_id = c.doc_id
ORDER BY dist ASC;
exit;
