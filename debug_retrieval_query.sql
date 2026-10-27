SET SERVEROUTPUT ON SIZE UNLIMITED;
SET DEFINE OFF;
ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

DECLARE
  l_q VARCHAR2(200) := 'Any pending task of siraj';
  l_detected_person VARCHAR2(100) := 'SIRAJ';
  l_search_q VARCHAR2(200) := 'NOT STARTED TASK SIRAJ';
  l_token1 VARCHAR2(100) := 'NOT';
  l_token2 VARCHAR2(100) := 'STARTED';
  l_token3 VARCHAR2(100) := 'TASK';
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== CHUNKS THAT MATCHED FOR: ' || l_search_q || ' ===');
  FOR r IN (
    WITH vec_cand AS (
      SELECT c.doc_id, c.chunk_id, c.chunk_no,
             VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING l_search_q AS data), COSINE) as dist
      FROM   source_docs d
      JOIN   doc_chunks c ON d.doc_id = c.doc_id
      WHERE  d.status = 'ACTIVE'
      ORDER BY dist ASC
      FETCH FIRST 40 ROWS ONLY
    ),
    key_cand AS (
      SELECT c.doc_id, c.chunk_id, c.chunk_no,
             CASE 
               WHEN l_detected_person IS NOT NULL AND UPPER(c.chunk_text) LIKE '%' || UPPER(l_detected_person) || '%'
                AND l_token1 IS NOT NULL AND UPPER(c.chunk_text) LIKE '%' || l_token1 || '%'
               THEN 0.0500
               WHEN l_detected_person IS NOT NULL AND UPPER(c.chunk_text) LIKE '%' || UPPER(l_detected_person) || '%'
               THEN 0.0800
               ELSE 0.3500
             END AS dist
      FROM   source_docs d
      JOIN   doc_chunks c ON d.doc_id = c.doc_id
      WHERE  d.status = 'ACTIVE'
        AND  (
             (l_detected_person IS NOT NULL AND UPPER(c.chunk_text) LIKE '%' || UPPER(l_detected_person) || '%')
         OR  (l_token1 IS NOT NULL AND LENGTH(l_token1) >= 3 AND UPPER(c.chunk_text) LIKE '%' || l_token1 || '%')
        )
      ORDER BY dist ASC
      FETCH FIRST 40 ROWS ONLY
    ),
    all_cand AS (
      SELECT doc_id, chunk_id, chunk_no, dist FROM vec_cand
      UNION ALL
      SELECT doc_id, chunk_id, chunk_no, dist FROM key_cand
    ),
    ranked_cand AS (
      SELECT doc_id, chunk_id, chunk_no, dist,
             ROW_NUMBER() OVER (PARTITION BY chunk_id ORDER BY dist ASC) as rn
      FROM all_cand
    )
    SELECT c.chunk_no, r.dist, SUBSTR(c.chunk_text, 1, 200) as chunk_preview
    FROM ranked_cand r
    JOIN doc_chunks c ON r.chunk_id = c.chunk_id
    WHERE r.rn = 1
    ORDER BY r.dist ASC
    FETCH FIRST 10 ROWS ONLY
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('Chunk ' || r.chunk_no || ' (Dist: ' || r.dist || '): ' || r.chunk_preview);
  END LOOP;
END;
/
EXIT;
