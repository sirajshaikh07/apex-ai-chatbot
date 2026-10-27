set linesize 200
SELECT c.chunk_id, d.title,
       ROUND(VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING 'Who is Safa Himmatkha Pathan' AS data), COSINE), 4) as dist_who,
       ROUND(VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING 'What is the person’s full name?' AS data), COSINE), 4) as dist_name,
       ROUND(VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING 'Tell me about bio data' AS data), COSINE), 4) as dist_bio
FROM source_docs d
JOIN doc_chunks c ON d.doc_id = c.doc_id;
exit;
