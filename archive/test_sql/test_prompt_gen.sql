SET SERVEROUTPUT ON SIZE UNLIMITED;
SET LINESIZE 250;

ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

DECLARE
  l_start_time      NUMBER := DBMS_UTILITY.GET_TIME;
  l_norm_q          VARCHAR2(4000);
  l_resolved_q      VARCHAR2(4000);
  l_detected_proj   VARCHAR2(50);
  l_detected_person VARCHAR2(100);
  l_is_proj_count   BOOLEAN := FALSE;

  l_clean_q         VARCHAR2(2000);
  l_search_q        VARCHAR2(4000);
  l_token1          VARCHAR2(100);
  l_token2          VARCHAR2(100);
  l_token3          VARCHAR2(100);

  l_context         CLOB := NULL;
  l_prompt          CLOB := NULL;
  l_history_context CLOB := NULL;
  l_entity_context  CLOB := NULL;
  l_chunk_cnt       NUMBER := 0;
  l_min_dist        NUMBER := 999;
  l_safe_chunk      VARCHAR2(4000);
  p_sources         VARCHAR2(1000) := '';
  p_question        VARCHAR2(1000) := 'Give me title of all task siraj completed';
  p_session_id      NUMBER := 998877;
  p_user_name       VARCHAR2(100) := 'ADMIN';
BEGIN
  DBMS_OUTPUT.PUT_LINE('Start step 1: Query resolution...');
  
  -- Query resolution
  enterprise_rag_pkg.resolve_query(
    p_raw_question   => p_question,
    p_session_id     => p_session_id,
    p_resolved_query => l_resolved_q,
    p_detected_proj  => l_detected_proj,
    p_detected_user  => l_detected_person,
    p_is_proj_count  => l_is_proj_count
  );
  DBMS_OUTPUT.PUT_LINE('Resolved: ' || l_resolved_q || ' | Person: ' || l_detected_person || ' | Proj: ' || l_detected_proj);
  DBMS_OUTPUT.PUT_LINE('Elapsed so far: ' || ((DBMS_UTILITY.GET_TIME - l_start_time)*10) || ' ms');

  l_search_q := enterprise_rag_pkg.resolve_hinglish(l_resolved_q);

  l_clean_q := REGEXP_REPLACE(UPPER(l_search_q), '[^A-Z0-9 ]', ' ');
  l_clean_q := REGEXP_REPLACE(l_clean_q, '\b(WHAT|WHEN|WHERE|WHICH|WHO|WHOM|WHOSE|WHY|HOW|THE|IS|ARE|WAS|WERE|AM|AN|A|IN|ON|AT|TO|FOR|OF|WITH|BY|FROM|ABOUT|TELL|ME|GIVE|SHOW|CAN|YOU|PLEASE|PERSON|DETAILS|DATA|INFO|INFORMATION)\b', ' ');
  l_clean_q := TRIM(REGEXP_REPLACE(l_clean_q, '\s+', ' '));
  l_token1  := REGEXP_SUBSTR(l_clean_q, '[^ ]+', 1, 1);
  l_token2  := REGEXP_SUBSTR(l_clean_q, '[^ ]+', 1, 2);
  l_token3  := REGEXP_SUBSTR(l_clean_q, '[^ ]+', 1, 3);

  DBMS_OUTPUT.PUT_LINE('Starting retrieval query...');
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
               WHEN (UPPER(p_question) LIKE '%COMPLET%' OR UPPER(p_question) LIKE '%DONE%' OR UPPER(p_question) LIKE '%FINISH%')
                AND UPPER(c.chunk_text) LIKE '%' || UPPER(NVL(l_detected_person, 'SIRAJ')) || '%'
                AND (UPPER(c.chunk_text) LIKE '%"DONE": TRUE%' OR UPPER(c.chunk_text) LIKE '%"STATUS": "DN"%' OR UPPER(c.chunk_text) LIKE '%STATUS: DONE%' OR UPPER(c.chunk_text) LIKE '%"DONE":TRUE%')
               THEN 0.0200
               WHEN UPPER(c.chunk_text) LIKE '%' || UPPER(NVL(l_detected_person, 'SIRAJ')) || '%'
                AND (UPPER(c.chunk_text) LIKE '%"NAME":%' OR UPPER(c.chunk_text) LIKE '%TASK%')
               THEN 0.0800
               WHEN UPPER(c.chunk_text) LIKE '%' || UPPER(NVL(l_detected_person, 'SIRAJ')) || '%'
               THEN 0.1200
               WHEN l_detected_proj IS NOT NULL AND UPPER(c.chunk_text) LIKE '%' || REPLACE(l_detected_proj, '_', ' ') || '%'
               THEN 0.2000
               ELSE 0.3000
             END AS dist
      FROM   source_docs d
      JOIN   doc_chunks c ON d.doc_id = c.doc_id
      WHERE  d.status = 'ACTIVE'
        AND  (
             (l_detected_person IS NOT NULL AND UPPER(c.chunk_text) LIKE '%' || UPPER(l_detected_person) || '%')
         OR  (UPPER(p_question) LIKE '%SIRAJ%' AND UPPER(c.chunk_text) LIKE '%SIRAJ%')
         OR  (l_detected_proj IS NOT NULL AND UPPER(c.chunk_text) LIKE '%' || REPLACE(l_detected_proj, '_', ' ') || '%')
         OR  (l_token1 IS NOT NULL AND LENGTH(l_token1) >= 3 AND UPPER(c.chunk_text) LIKE '%' || l_token1 || '%')
         OR  (l_token2 IS NOT NULL AND LENGTH(l_token2) >= 3 AND UPPER(c.chunk_text) LIKE '%' || l_token2 || '%')
         OR  (l_token3 IS NOT NULL AND LENGTH(l_token3) >= 3 AND UPPER(c.chunk_text) LIKE '%' || l_token3 || '%')
        )
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
      WHERE cand_rank <= CASE WHEN (UPPER(p_question) LIKE '%ALL%' OR UPPER(p_question) LIKE '%LIST%' OR UPPER(p_question) LIKE '%EVERY%' OR UPPER(p_question) LIKE '%TITLE%' OR UPPER(p_question) LIKE '%SAB%' OR UPPER(p_question) LIKE '%SAARE%') THEN 30 ELSE 6 END
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
    l_chunk_cnt := l_chunk_cnt + 1;
    l_safe_chunk := REGEXP_REPLACE(r.chunk_text, '(ignore|disregard)\s+(all|any|previous)\s+(instructions|prompts|rules)', '[FILTERED]', 1, 0, 'i');
    l_safe_chunk := REGEXP_REPLACE(l_safe_chunk, 'system\s*prompt\s*:', '[FILTERED]', 1, 0, 'i');

    IF INSTR(l_safe_chunk, '"reqDl"') > 0 OR INSTR(l_safe_chunk, '"thread"') > 0 THEN
      l_safe_chunk := REGEXP_REPLACE(l_safe_chunk, '"reqDl"\s*:\s*null\s*,?\s*', '');
      l_safe_chunk := REGEXP_REPLACE(l_safe_chunk, '"reqDlStatus"\s*:\s*null\s*,?\s*', '');
      l_safe_chunk := REGEXP_REPLACE(l_safe_chunk, '"reqReason"\s*:\s*null\s*,?\s*', '');
      l_safe_chunk := REGEXP_REPLACE(l_safe_chunk, '"thread"\s*:\s*,?\s*', '');
      l_safe_chunk := REGEXP_REPLACE(l_safe_chunk, '"desc"\s*:\s*""\s*,?\s*', '');
      l_safe_chunk := REGEXP_REPLACE(l_safe_chunk, '"frequency"\s*:\s*"once"\s*,?\s*', '');
    END IF;

    IF NVL(DBMS_LOB.GETLENGTH(l_context), 0) < 14000 THEN
      l_context := NVL(l_context, '') || CHR(10) ||
        '<passage document="' || r.title || '" chunk="' || r.chunk_no || '">' || CHR(10) ||
        DBMS_LOB.SUBSTR(l_safe_chunk, 1500, 1) || CHR(10) ||
        '</passage>';
      IF INSTR(NVL(p_sources, ' '), r.title) = 0 THEN
        IF p_sources IS NOT NULL THEN p_sources := p_sources || ', '; END IF;
        p_sources := p_sources || r.title;
      END IF;
    END IF;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('Retrieval complete! Elapsed: ' || ((DBMS_UTILITY.GET_TIME - l_start_time)*10) || ' ms');
  DBMS_OUTPUT.PUT_LINE('Total Chunks Retrieved: ' || l_chunk_cnt);
  DBMS_OUTPUT.PUT_LINE('Context Length: ' || NVL(LENGTH(l_context), 0) || ' chars');
  DBMS_OUTPUT.PUT_LINE('Sources: ' || p_sources);
END;
/
EXIT;
