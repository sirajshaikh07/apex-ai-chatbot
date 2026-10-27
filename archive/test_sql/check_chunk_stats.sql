SELECT d.doc_id, d.title, count(c.chunk_id) as chunks_cnt,
       AVG(REGEXP_COUNT(c.chunk_text, '\S+')) as avg_words,
       MAX(REGEXP_COUNT(c.chunk_text, '\S+')) as max_words
FROM   source_docs d
LEFT JOIN doc_chunks c ON d.doc_id = c.doc_id
GROUP BY d.doc_id, d.title
ORDER BY d.doc_id;
exit;
