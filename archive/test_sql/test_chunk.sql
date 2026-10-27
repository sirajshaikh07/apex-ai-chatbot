set echo on feedback on serveroutput on linesize 200

PROMPT 1. Testing simple VECTOR_CHUNKS query
SELECT d.doc_id, c.chunk_offset, c.chunk_length, SUBSTR(c.chunk_text, 1, 50) as snippet
FROM   source_docs d,
       VECTOR_CHUNKS(d.content BY words MAX 150 OVERLAP 15
                     SPLIT BY recursively LANGUAGE american NORMALIZE all) c;

PROMPT 2. Testing VECTOR_EMBEDDING query
SELECT VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING 'test' AS data) FROM dual;

PROMPT 3. Testing INSERT query
INSERT INTO doc_chunks (doc_id, chunk_no, chunk_text, embedding)
SELECT d.doc_id, 
       ROW_NUMBER() OVER (PARTITION BY d.doc_id ORDER BY c.chunk_offset),
       c.chunk_text,
       VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING c.chunk_text AS data)
FROM   source_docs d,
       VECTOR_CHUNKS(d.content BY words MAX 150 OVERLAP 15
                     SPLIT BY recursively LANGUAGE american NORMALIZE all) c;

ROLLBACK;
exit;
