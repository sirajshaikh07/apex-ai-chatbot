SET SERVEROUTPUT ON SIZE UNLIMITED;
SET LINESIZE 250;

ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

DECLARE
  l_t0 NUMBER;
  l_t1 NUMBER;
  l_cnt NUMBER := 0;
  l_ctx CLOB;
  l_search_q VARCHAR2(200) := 'Give me title of all task siraj completed';
  l_question VARCHAR2(200) := 'Give me title of all task siraj completed';
  l_detected_person VARCHAR2(50) := 'Siraj';
  l_detected_proj   VARCHAR2(50) := NULL;
  l_token1 VARCHAR2(50) := 'TASK';
  l_token2 VARCHAR2(50) := 'SIRAJ';
  l_token3 VARCHAR2(50) := 'COMPLETED';
BEGIN
  DBMS_OUTPUT.PUT_LINE('=== 1. ACTIVE DOCUMENTS ===');
  FOR d IN (SELECT doc_id, title, status, file_size FROM source_docs WHERE status = 'ACTIVE') LOOP
    SELECT COUNT(*) INTO l_cnt FROM doc_chunks WHERE doc_id = d.doc_id;
    DBMS_OUTPUT.PUT_LINE('Doc ' || d.doc_id || ': ' || d.title || ' (' || d.file_size || ' bytes, ' || l_cnt || ' chunks)');
  END LOOP;

  DBMS_OUTPUT.PUT_LINE(CHR(10) || '=== 2. BENCHMARKING RETRIEVAL QUERY ===');
  l_t0 := DBMS_UTILITY.GET_TIME;

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
               WHEN UPPER(c.chunk_text) LIKE '%SIRAJ%' AND (UPPER(c.chunk_text) LIKE '%"DONE": TRUE%' OR UPPER(c.chunk_text) LIKE '%"STATUS": "DN"%' OR UPPER(c.chunk_text) LIKE '%STATUS: DONE%' OR UPPER(c.chunk_text) LIKE '%"DONE":TRUE%')
               THEN 0.0200
               WHEN UPPER(c.chunk_text) LIKE '%SIRAJ%' AND (UPPER(c.chunk_text) LIKE '%"NAME":%' OR UPPER(c.chunk_text) LIKE '%TASK%')
               THEN 0.0800
               WHEN UPPER(c.chunk_text) LIKE '%SIRAJ%'
               THEN 0.1200
               ELSE 0.3000
             END AS dist
      FROM   source_docs d
      JOIN   doc_chunks c ON d.doc_id = c.doc_id
      WHERE  d.status = 'ACTIVE'
        AND  UPPER(c.chunk_text) LIKE '%SIRAJ%'
      ORDER BY dist ASC, c.doc_id, c.chunk_no
      FETCH FIRST 60 ROWS ONLY
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
      WHERE cand_rank <= 30
    ),
    neighbor_cand AS (
      SELECT c.chunk_id, t.dist,
             ROW_NUMBER() OVER (PARTITION BY c.chunk_id ORDER BY t.dist ASC) as rn
      FROM top_cand t
      JOIN doc_chunks c 
        ON c.doc_id = t.doc_id 
       AND c.chunk_no BETWEEN GREATEST(1, t.chunk_no - 1) AND (t.chunk_no + 1)
    )
    SELECT d.title, c.chunk_id, c.chunk_no, c.chunk_text, n.dist
    FROM neighbor_cand n
    JOIN doc_chunks c ON n.chunk_id = c.chunk_id
    JOIN source_docs d ON c.doc_id = d.doc_id
    WHERE n.rn = 1 AND d.status = 'ACTIVE'
    ORDER BY c.doc_id, c.chunk_no
  ) LOOP
    l_cnt := l_cnt + 1;
    l_ctx := NVL(l_ctx, '') || CHR(10) || r.chunk_text;
  END LOOP;

  l_t1 := DBMS_UTILITY.GET_TIME;
  DBMS_OUTPUT.PUT_LINE('Retrieval took: ' || ((l_t1 - l_t0)*10) || ' ms. Rows: ' || l_cnt || ', Context length: ' || NVL(LENGTH(l_ctx), 0) || ' chars');
END;
/
EXIT;
