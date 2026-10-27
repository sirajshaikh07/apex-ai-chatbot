set serveroutput on size unlimited feedback off linesize 120
DECLARE
  l_start NUMBER := DBMS_UTILITY.GET_TIME;
  l_cnt NUMBER := 0;
  l_resolved_q VARCHAR2(100) := 'How many projects are there';
  l_detected_proj VARCHAR2(50) := NULL;
  l_detected_person VARCHAR2(50) := NULL;
BEGIN
  FOR r IN (
      WITH vec_cand AS (
        SELECT c.chunk_id,
               ROUND(VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING l_resolved_q AS data), COSINE), 4) as dist
        FROM   source_docs d
        JOIN   doc_chunks c ON d.doc_id = c.doc_id
        ORDER BY dist ASC
        FETCH FIRST 6 ROWS ONLY
      ),
      key_cand AS (
        SELECT c.chunk_id,
               0.3000 AS dist
        FROM   source_docs d
        JOIN   doc_chunks c ON d.doc_id = c.doc_id
        WHERE  (l_detected_proj IS NOT NULL AND UPPER(c.chunk_text) LIKE '%' || REPLACE(l_detected_proj, '_', ' ') || '%')
           OR  (l_detected_person IS NOT NULL AND UPPER(c.chunk_text) LIKE '%' || UPPER(l_detected_person) || '%')
        FETCH FIRST 6 ROWS ONLY
      ),
      all_cand AS (
        SELECT chunk_id, dist FROM vec_cand
        UNION ALL
        SELECT chunk_id, dist FROM key_cand
      ),
      ranked_cand AS (
        SELECT chunk_id, dist,
               ROW_NUMBER() OVER (PARTITION BY chunk_id ORDER BY dist ASC) as rn
        FROM all_cand
      ),
      top_cand AS (
        SELECT chunk_id, dist
        FROM ranked_cand
        WHERE rn = 1
        ORDER BY dist ASC
        FETCH FIRST 5 ROWS ONLY
      )
      SELECT d.title, c.chunk_text, t.dist
      FROM top_cand t
      JOIN doc_chunks c ON t.chunk_id = c.chunk_id
      JOIN source_docs d ON c.doc_id = d.doc_id
  ) LOOP
    l_cnt := l_cnt + 1;
  END LOOP;
  dbms_output.put_line('CTE time: ' || ((DBMS_UTILITY.GET_TIME - l_start)*10) || ' ms, rows: ' || l_cnt);
END;
/
exit;
