set serveroutput on size unlimited feedback off linesize 200
DECLARE
  l_context         CLOB := '';
  l_prompt          CLOB;
  l_history_context CLOB := '';
  l_entity_context  CLOB := '';
  l_chunk_cnt       NUMBER := 0;
  p_sources         VARCHAR2(1000) := '';
  l_resolved_q      VARCHAR2(1000) := 'Who is Safa Himmatkha Pathan';
  l_detected_proj   VARCHAR2(50) := NULL;
  l_detected_person VARCHAR2(100) := NULL;
  p_question        VARCHAR2(1000) := 'Who is Safa Himmatkha Pathan';
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
        FETCH FIRST 3 ROWS ONLY
      )
      SELECT d.title, c.chunk_text, t.dist
      FROM top_cand t
      JOIN doc_chunks c ON t.chunk_id = c.chunk_id
      JOIN source_docs d ON c.doc_id = d.doc_id
    ) LOOP
      -- Context window budgeting: cap total raw chunk context at 4,000 chars
      IF LENGTH(l_context) < 4000 THEN
        l_chunk_cnt := l_chunk_cnt + 1;
        l_context := l_context || CHR(10) || '--- Document: ' || r.title || ' ---' || CHR(10) || SUBSTR(r.chunk_text, 1, 1500) || CHR(10);
        IF INSTR(NVL(p_sources, ' '), r.title) = 0 THEN
          IF p_sources IS NOT NULL THEN
            p_sources := p_sources || ', ';
          END IF;
          p_sources := p_sources || r.title;
        END IF;
      END IF;
    END LOOP;

    dbms_output.put_line('CHUNK CNT: ' || l_chunk_cnt);
    dbms_output.put_line('SOURCES: ' || p_sources);
    dbms_output.put_line('CONTEXT LEN: ' || LENGTH(l_context));
    dbms_output.put_line('CONTEXT PREVIEW:');
    dbms_output.put_line(SUBSTR(l_context, 1, 500));
END;
/
exit;
