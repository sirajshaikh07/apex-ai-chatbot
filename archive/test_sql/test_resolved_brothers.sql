set define off serveroutput on size unlimited feedback off linesize 200 pagesize 0 trimout on
DECLARE
  l_raw VARCHAR2(500) := 'Safa ke kitne bhai hain aur wo kya karte hain?';
  l_resolved VARCHAR2(500) := 'Safa brother count occupation work';
  l_context CLOB := '';
  l_prompt  CLOB;
  l_ans     CLOB;
  l_app_id  NUMBER;
BEGIN
  -- Retrieval using resolved English query
  FOR r IN (
    WITH vec_cand AS (
      SELECT c.chunk_id,
             ROUND(VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING l_resolved AS data), COSINE), 4) as dist
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
      WHERE  UPPER(c.chunk_text) LIKE '%SAFA%'
         OR  UPPER(c.chunk_text) LIKE '%BROTHER%'
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
      FETCH FIRST 4 ROWS ONLY
    )
    SELECT d.title, c.chunk_no, c.chunk_text, t.dist
    FROM top_cand t
    JOIN doc_chunks c ON t.chunk_id = c.chunk_id
    JOIN source_docs d ON c.doc_id = d.doc_id
  ) LOOP
    dbms_output.put_line('Retrieved: ' || r.title || ' Chunk ' || r.chunk_no || ' (Dist: ' || r.dist || ')');
    l_context := l_context || CHR(10) || '--- Document: ' || r.title || ' ---' || CHR(10) || r.chunk_text || CHR(10);
  END LOOP;

  -- Build prompt passing ORIGINAL Hinglish question
  l_prompt := 'You are an intelligent, accurate, and professional Enterprise AI Assistant.' || CHR(10) ||
              'Answer the question accurately, directly, and strictly based ONLY on the following documentation.' || CHR(10) ||
              'Language Instruction: Respond in the user''s language (if user asked in Hindi/Hinglish, answer in clean Hinglish/Hindi).' || CHR(10) || CHR(10) ||
              'RELEVANT DOCUMENTATION PASSAGES:' || CHR(10) ||
              l_context || CHR(10) ||
              'Current User Question: ' || l_raw || CHR(10) ||
              'Assistant Answer:';

  -- Session
  IF apex_application.g_flow_id IS NULL THEN
    SELECT application_id INTO l_app_id FROM apex_applications WHERE application_id = 101 FETCH FIRST 1 ROWS ONLY;
    apex_session.create_session(p_app_id => l_app_id, p_page_id => 1, p_username => 'ADMIN');
  END IF;

  l_ans := apex_ai.generate(
    p_service_static_id => 'local_ollama',
    p_prompt            => l_prompt
  );

  dbms_output.put_line('=== FINAL ANSWER ===');
  dbms_output.put_line(l_ans);
END;
/
exit;
