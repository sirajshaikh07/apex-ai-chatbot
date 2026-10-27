SET SERVEROUTPUT ON SIZE UNLIMITED;
SET DEFINE OFF;
ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

DECLARE
  p_raw_q VARCHAR2(1000) := 'Q1: How long is the probationary period for new appointments, and by how much can it be extended?';
  l_clean_q VARCHAR2(1000);
  l_context CLOB := NULL;
  l_prompt  CLOB;
  l_ans     CLOB;
  l_src     VARCHAR2(1000);
  l_app_id  NUMBER;
BEGIN
  -- 1. Clean query
  l_clean_q := REGEXP_REPLACE(p_raw_q, '^(Q\d+[:.]?|Question\s*\d*[:.]?|\d+[\).])\s*', '', 1, 1, 'i');
  DBMS_OUTPUT.PUT_LINE('Cleaned Query: ' || l_clean_q);

  -- 2. Retrieve top passages using pure vector + adjacent window
  FOR r IN (
    WITH vec_cand AS (
      SELECT c.doc_id, c.chunk_id, c.chunk_no,
             ROUND(VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING l_clean_q AS data), COSINE), 4) as dist
      FROM   source_docs d
      JOIN   doc_chunks c ON d.doc_id = c.doc_id
      WHERE  d.status = 'ACTIVE'
      ORDER BY dist ASC
      FETCH FIRST 4 ROWS ONLY
    ),
    retrieved_cand AS (
      SELECT c.chunk_id, t.dist,
             ROW_NUMBER() OVER (PARTITION BY c.chunk_id ORDER BY t.dist ASC) as rn
      FROM vec_cand t
      JOIN doc_chunks c 
        ON c.doc_id = t.doc_id 
       AND c.chunk_no BETWEEN GREATEST(1, t.chunk_no - 1) AND (t.chunk_no + 1)
    )
    SELECT d.title, c.chunk_id, c.chunk_no, c.chunk_text, n.dist
    FROM retrieved_cand n
    JOIN doc_chunks c ON n.chunk_id = c.chunk_id
    JOIN source_docs d ON c.doc_id = d.doc_id
    WHERE n.rn = 1 AND d.status = 'ACTIVE'
    ORDER BY n.dist ASC, c.doc_id, c.chunk_no
  ) LOOP
    IF NVL(DBMS_LOB.GETLENGTH(l_context), 0) < 3500 THEN
      l_context := NVL(l_context, '') || CHR(10) ||
        '<passage document="' || r.title || '" chunk="' || r.chunk_no || '">' || CHR(10) ||
        DBMS_LOB.SUBSTR(r.chunk_text, 1500, 1) || CHR(10) ||
        '</passage>';

      IF INSTR(NVL(l_src, ' '), r.title) = 0 THEN
        IF l_src IS NOT NULL THEN l_src := l_src || ', '; END IF;
        l_src := l_src || r.title;
      END IF;
    END IF;
  END LOOP;

  DBMS_OUTPUT.PUT_LINE('Retrieved Sources: ' || l_src);
  DBMS_OUTPUT.PUT_LINE('Context Length:    ' || DBMS_LOB.GETLENGTH(l_context));

  -- 3. Construct Master Prompt
  l_prompt := 'You are an intelligent, accurate, and professional Enterprise AI Assistant.' || CHR(10) ||
              'Your goal is to provide precise, direct, and factually grounded answers to the user based STRICTLY on the retrieved document passages provided below.' || CHR(10) || CHR(10) ||
              'CRITICAL RULES:' || CHR(10) ||
              '1. Strict Grounding: Base your answer strictly on the RELEVANT DOCUMENTATION PASSAGES provided below. Do NOT hallucinate, infer, or assume facts not explicitly mentioned.' || CHR(10) ||
              '2. Exact Attribution: Associate every fact, rule, policy, date, number, or condition ONLY with the specific subject or record it explicitly belongs to.' || CHR(10) ||
              '3. Missing Information: If the requested information is NOT contained in the provided passages, explicitly state: "The provided document does not contain information about [requested topic]."' || CHR(10) ||
              '4. Clean Formatting: Be concise, direct, and clear.' || CHR(10) || CHR(10) ||
              'RELEVANT DOCUMENTATION PASSAGES:' || CHR(10) ||
              '<document_context>' || l_context || CHR(10) || '</document_context>' || CHR(10) || CHR(10) ||
              'Current User Question: ' || p_raw_q || CHR(10) ||
              'Assistant Answer:';

  -- 4. Ensure APEX session
  IF apex_application.g_flow_id IS NULL THEN
    BEGIN
      SELECT application_id INTO l_app_id FROM apex_applications WHERE application_id = 101 FETCH FIRST 1 ROWS ONLY;
      apex_session.create_session(p_app_id => l_app_id, p_page_id => 1, p_username => 'ADMIN');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        SELECT application_id INTO l_app_id FROM apex_applications FETCH FIRST 1 ROWS ONLY;
        apex_session.create_session(p_app_id => l_app_id, p_page_id => 1, p_username => 'ADMIN');
    END;
  END IF;

  -- 5. Call Ollama
  l_ans := apex_ai.generate(
    p_service_static_id => 'local_ollama',
    p_prompt            => l_prompt
  );

  DBMS_OUTPUT.PUT_LINE('============================================================');
  DBMS_OUTPUT.PUT_LINE('ANSWER FROM OLLAMA (qwen2.5:7b):');
  DBMS_OUTPUT.PUT_LINE(l_ans);
  DBMS_OUTPUT.PUT_LINE('============================================================');
END;
/
EXIT;
