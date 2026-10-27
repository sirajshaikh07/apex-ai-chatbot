SET SERVEROUTPUT ON SIZE UNLIMITED;
SET DEFINE OFF;
ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

DECLARE
  l_search_q VARCHAR2(4000) := 'Q1 How long is probationary period for new appointments and by how much can it be extended';
  l_token1 VARCHAR2(100) := 'Q1';
  l_token2 VARCHAR2(100) := 'HOW';
  l_token3 VARCHAR2(100) := 'LONG';
  l_detected_person VARCHAR2(100) := NULL;
  p_question VARCHAR2(1000) := 'Q1: How long is the probationary period for new appointments, and by how much can it be extended?';
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- TOP_CAND AND RETRIEVED_CAND ---');
  FOR r IN (
      WITH vec_cand AS (
        SELECT c.doc_id, c.chunk_id, c.chunk_no,
               ROUND(VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING l_search_q AS data), COSINE), 4) as dist
        FROM   source_docs d
        JOIN   doc_chunks c ON d.doc_id = c.doc_id
        WHERE  d.status = 'ACTIVE'
        ORDER BY dist ASC
        FETCH FIRST 30 ROWS ONLY
      ),
      key_cand AS (
        SELECT c.doc_id, c.chunk_id, c.chunk_no,
               CASE
                 WHEN l_token1 IS NOT NULL AND LENGTH(l_token1) >= 3 AND UPPER(c.chunk_text) LIKE '%' || l_token1 || '%'
                  AND l_token2 IS NOT NULL AND LENGTH(l_token2) >= 3 AND UPPER(c.chunk_text) LIKE '%' || l_token2 || '%'
                 THEN 0.0800
                 WHEN l_token1 IS NOT NULL AND LENGTH(l_token1) >= 3 AND UPPER(c.chunk_text) LIKE '%' || l_token1 || '%'
                 THEN 0.1800
                 ELSE 0.3500
               END AS dist
        FROM   source_docs d
        JOIN   doc_chunks c ON d.doc_id = c.doc_id
        WHERE  d.status = 'ACTIVE'
          AND  (
               (l_token1 IS NOT NULL AND LENGTH(l_token1) >= 3 AND UPPER(c.chunk_text) LIKE '%' || l_token1 || '%')
           OR  (l_token2 IS NOT NULL AND LENGTH(l_token2) >= 3 AND UPPER(c.chunk_text) LIKE '%' || l_token2 || '%')
           OR  (l_token3 IS NOT NULL AND LENGTH(l_token3) >= 3 AND UPPER(c.chunk_text) LIKE '%' || l_token3 || '%')
          )
        ORDER BY dist ASC, c.doc_id, c.chunk_no
        FETCH FIRST 80 ROWS ONLY
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
      ),
      ordered_cand AS (
        SELECT doc_id, chunk_id, chunk_no, dist,
               ROW_NUMBER() OVER (ORDER BY dist ASC) as cand_rank
        FROM ranked_cand
        WHERE rn = 1
      ),
      top_cand AS (
        SELECT doc_id, chunk_id, chunk_no, dist
        FROM ordered_cand
        WHERE cand_rank <= 8
      ),
      retrieved_cand AS (
        SELECT c.chunk_id, t.dist,
               ROW_NUMBER() OVER (PARTITION BY c.chunk_id ORDER BY t.dist ASC) as rn
        FROM top_cand t
        JOIN doc_chunks c 
          ON c.doc_id = t.doc_id 
         AND (
           ( (l_detected_person IS NOT NULL OR UPPER(p_question) LIKE '%ALL%' OR UPPER(p_question) LIKE '%LIST%' OR UPPER(p_question) LIKE '%EVERY%' OR UPPER(p_question) LIKE '%TITLE%' OR UPPER(p_question) LIKE '%SAB%' OR UPPER(p_question) LIKE '%SAARE%')
             AND c.chunk_id = t.chunk_id )
           OR
           ( l_detected_person IS NULL
             AND NOT (UPPER(p_question) LIKE '%ALL%' OR UPPER(p_question) LIKE '%LIST%' OR UPPER(p_question) LIKE '%EVERY%' OR UPPER(p_question) LIKE '%TITLE%' OR UPPER(p_question) LIKE '%SAB%' OR UPPER(p_question) LIKE '%SAARE%')
             AND c.chunk_no BETWEEN GREATEST(1, t.chunk_no - 1) AND (t.chunk_no + 1) )
         )
      )
      SELECT d.title, c.chunk_id, c.chunk_no, n.dist
      FROM retrieved_cand n
      JOIN doc_chunks c ON n.chunk_id = c.chunk_id
      JOIN source_docs d ON c.doc_id = d.doc_id
      WHERE n.rn = 1 AND d.status = 'ACTIVE'
      ORDER BY n.dist ASC, c.doc_id, c.chunk_no
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('Retrieved: doc=' || r.title || ' chunk_id=' || r.chunk_id || ' chunk_no=' || r.chunk_no || ' dist=' || r.dist);
  END LOOP;
END;
/
EXIT;
