set serveroutput on size unlimited feedback off linesize 200
DECLARE
  l_context         CLOB := '';
  l_chunk_cnt       NUMBER := 0;
  p_sources         VARCHAR2(1000) := '';
  l_resolved_q      VARCHAR2(1000) := 'Who is Safa Himmatkha Pathan';
BEGIN
    FOR r IN (
      SELECT d.title, c.chunk_text,
             ROUND(VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING l_resolved_q AS data), COSINE), 4) as dist
      FROM   source_docs d
      JOIN   doc_chunks c ON d.doc_id = c.doc_id
      ORDER BY dist ASC
      FETCH FIRST 3 ROWS ONLY
    ) LOOP
      IF NVL(LENGTH(l_context), 0) < 4000 THEN
        l_chunk_cnt := l_chunk_cnt + 1;
        l_context := l_context || CHR(10) || '--- Document: ' || r.title || ' ---' || CHR(10) || SUBSTR(r.chunk_text, 1, 1500) || CHR(10);
        p_sources := r.title;
      END IF;
    END LOOP;

    dbms_output.put_line('CHUNK CNT: ' || l_chunk_cnt);
    dbms_output.put_line('SOURCES: ' || p_sources);
    dbms_output.put_line('CONTEXT LEN: ' || LENGTH(l_context));
    dbms_output.put_line('PREVIEW: ' || SUBSTR(l_context, 1, 300));
END;
/
exit;
