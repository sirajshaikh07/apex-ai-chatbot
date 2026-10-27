SET SERVEROUTPUT ON SIZE UNLIMITED;
SET DEFINE OFF;
ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

DECLARE
  p_question VARCHAR2(1000) := 'Q1: How long is the probationary period for new appointments, and by how much can it be extended?';
  l_resolved_q VARCHAR2(4000);
  l_detected_proj VARCHAR2(50);
  l_detected_person VARCHAR2(100);
  l_is_proj_count BOOLEAN;
  l_search_q VARCHAR2(4000);
  l_clean_q  VARCHAR2(2000);
  l_token1   VARCHAR2(100);
  l_token2   VARCHAR2(100);
  l_token3   VARCHAR2(100);
BEGIN
  -- We inspect what happens inside ask_with_context
  l_resolved_q := p_question;
  l_search_q := enterprise_rag_pkg.resolve_hinglish(l_resolved_q);
  DBMS_OUTPUT.PUT_LINE('Search query: ' || l_search_q);

  l_clean_q := REGEXP_REPLACE(UPPER(l_search_q), '[^A-Z0-9 ]', ' ');
  l_clean_q := REGEXP_REPLACE(l_clean_q, '\b(WHAT|WHEN|WHERE|WHICH|WHO|WHOM|WHOSE|WHY|HOW|THE|IS|ARE|WAS|WERE|AM|AN|A|IN|ON|AT|TO|FOR|OF|WITH|BY|FROM|ABOUT|TELL|ME|GIVE|SHOW|CAN|YOU|PLEASE|PERSON|DETAILS|DATA|INFO|INFORMATION)\b', ' ');
  l_clean_q := TRIM(REGEXP_REPLACE(l_clean_q, '\s+', ' '));
  l_token1  := REGEXP_SUBSTR(l_clean_q, '[^ ]+', 1, 1);
  l_token2  := REGEXP_SUBSTR(l_clean_q, '[^ ]+', 1, 2);
  l_token3  := REGEXP_SUBSTR(l_clean_q, '[^ ]+', 1, 3);
  DBMS_OUTPUT.PUT_LINE('Tokens: t1=' || l_token1 || ', t2=' || l_token2 || ', t3=' || l_token3);

  DBMS_OUTPUT.PUT_LINE('--- VEC_CAND ---');
  FOR v IN (
    SELECT c.doc_id, d.title, c.chunk_id, c.chunk_no,
           ROUND(VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING l_search_q AS data), COSINE), 4) as dist
    FROM   source_docs d
    JOIN   doc_chunks c ON d.doc_id = c.doc_id
    WHERE  d.status = 'ACTIVE'
    ORDER BY dist ASC
    FETCH FIRST 5 ROWS ONLY
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('Vec doc=' || v.doc_id || ' (' || v.title || ') chunk=' || v.chunk_no || ' dist=' || v.dist);
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('--- KEY_CAND ---');
  FOR k IN (
    SELECT c.doc_id, d.title, c.chunk_id, c.chunk_no,
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
    FETCH FIRST 5 ROWS ONLY
  ) LOOP
    DBMS_OUTPUT.PUT_LINE('Key doc=' || k.doc_id || ' (' || k.title || ') chunk=' || k.chunk_no || ' dist=' || k.dist);
  END LOOP;

END;
/
EXIT;
