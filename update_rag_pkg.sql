set define off serveroutput on linesize 200 feedback on

PROMPT ========================================================
PROMPT   Updating POLICY_RAG_PKG with Greeting & Smart Retrieval
PROMPT ========================================================

CREATE OR REPLACE PACKAGE policy_rag_pkg AS
  PROCEDURE ask_with_sources (
    p_question IN  VARCHAR2,
    p_answer   OUT CLOB,
    p_sources  OUT VARCHAR2
  );

  FUNCTION ask (
    p_question IN VARCHAR2
  ) RETURN CLOB;
END policy_rag_pkg;
/

CREATE OR REPLACE PACKAGE BODY policy_rag_pkg AS

  PROCEDURE ask_with_sources (
    p_question IN  VARCHAR2,
    p_answer   OUT CLOB,
    p_sources  OUT VARCHAR2
  ) IS
    l_app_id     NUMBER;
    l_context    CLOB := '';
    l_prompt     CLOB;
    l_norm_q     VARCHAR2(1000);
    l_min_dist   NUMBER := 999;
    l_chunk_cnt  NUMBER := 0;
  BEGIN
    p_sources := '';

    -- 1. Normalize query for greeting & conversational detection
    l_norm_q := TRIM(LOWER(REGEXP_REPLACE(p_question, '[^a-zA-Z0-9 ]', '')));

    -- 2. Detect Greetings & Conversational Pleasantries
    IF l_norm_q IN ('hi', 'hii', 'hiii', 'hello', 'hey', 'heyy', 'hola', 'namaste', 'greetings', 'yo')
       OR l_norm_q LIKE 'hi %' OR l_norm_q LIKE 'hii %' OR l_norm_q LIKE 'hello %' OR l_norm_q LIKE 'hey %'
       OR l_norm_q IN ('good morning', 'good afternoon', 'good evening', 'good day')
       OR l_norm_q IN ('who are you', 'what are you', 'what can you do', 'how can you help', 'help', 'introduce yourself')
       OR l_norm_q LIKE 'who are you%' OR l_norm_q LIKE 'what can you do%' OR l_norm_q LIKE 'how can you help%'
    THEN
      p_answer := 'Hello! 👋 I am your Enterprise Policy & Compliance AI Assistant.' || CHR(10) || CHR(10) ||
                  'I am trained on your organization''s verified documentation and can help you with:' || CHR(10) ||
                  '• Incident response SLAs & critical escalation paths' || CHR(10) ||
                  '• Annual leave policies, entitlements & carryover rules' || CHR(10) ||
                  '• Information security, data classification & encryption standards' || CHR(10) ||
                  '• Travel & business expense reimbursement guidelines' || CHR(10) || CHR(10) ||
                  'What would you like to know?';
      p_sources := NULL;
      RETURN;
    END IF;

    -- 3. Detect "How are you" & Personal Inquiries
    IF l_norm_q IN ('how are you', 'how are you doing', 'how do you do', 'how r u', 'how is it going', 'how are u', 'whats up', 'what is up')
       OR l_norm_q LIKE 'how are you%' OR l_norm_q LIKE 'how are u%'
    THEN
      p_answer := 'I am doing great, thank you for asking! 😊 I am ready to help you with company policies, guidelines, and procedures. What would you like to know?';
      p_sources := NULL;
      RETURN;
    END IF;

    -- 4. Detect "Where are you from" & Origin Inquiries
    IF l_norm_q IN ('where are you from', 'where are you', 'where do you live', 'where are you located', 'who created you', 'who made you', 'who built you', 'what is your name')
       OR l_norm_q LIKE 'where are you from%' OR l_norm_q LIKE 'who created you%' OR l_norm_q LIKE 'who made you%'
    THEN
      p_answer := 'I am your Enterprise Policy & Compliance AI Assistant, running securely inside your organization on Oracle Database 26ai and Oracle APEX.';
      p_sources := NULL;
      RETURN;
    END IF;

    -- 5. Detect Gratitude & Closings
    IF l_norm_q IN ('thanks', 'thank you', 'thx', 'thank you so much', 'bye', 'goodbye', 'see you', 'ok', 'okay', 'great', 'awesome', 'cool') THEN
      p_answer := 'You are very welcome! Let me know if you need any other policy or compliance assistance. Have a great day!';
      p_sources := NULL;
      RETURN;
    END IF;

    -- 6. In-DB Vector Search for Top-2 relevant chunks in Oracle 26ai
    FOR r IN (
      SELECT d.title, c.chunk_text,
             ROUND(VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING p_question AS data), COSINE), 4) as dist
      FROM   source_docs d
      JOIN   doc_chunks c ON d.doc_id = c.doc_id
      ORDER BY dist ASC
      FETCH FIRST 2 ROWS ONLY
    ) LOOP
      l_chunk_cnt := l_chunk_cnt + 1;
      IF r.dist < l_min_dist THEN
        l_min_dist := r.dist;
      END IF;

      l_context := l_context || CHR(10) || '--- Document: ' || r.title || ' ---' || CHR(10) || r.chunk_text || CHR(10);
      IF INSTR(NVL(p_sources, ' '), r.title) = 0 THEN
        IF p_sources IS NOT NULL THEN
          p_sources := p_sources || ', ';
        END IF;
        p_sources := p_sources || r.title;
      END IF;
    END LOOP;

    -- If no documents exist in knowledge base
    IF l_chunk_cnt = 0 THEN
      p_answer := 'No policy documents are currently uploaded in the knowledge base. Please ask an administrator to upload documents.';
      p_sources := NULL;
      RETURN;
    END IF;

    -- 7. Build Grounded Prompt with Strict Anti-Hallucination Guardrails
    l_prompt := 'You are an enterprise AI policy assistant. ' ||
                'Answer the question accurately, clearly, and strictly based ONLY on the following policy context.' || CHR(10) ||
                'Guidelines:' || CHR(10) ||
                '1. If the information needed to answer the question is not available in the context, reply strictly with: ' ||
                '"I could not find information regarding this in the uploaded company policy documents. Please contact HR or the IT Compliance team for clarification."' || CHR(10) ||
                '2. Do not assume or guess any facts.' || CHR(10) ||
                '3. Answer directly and concisely.' || CHR(10) || CHR(10) ||
                'Policy Context:' || CHR(10) ||
                l_context || CHR(10) ||
                'Question: ' || p_question || CHR(10) ||
                'Answer:';

    -- 8. Ensure APEX Session exists for APEX_AI
    IF apex_application.g_flow_id IS NULL THEN
      BEGIN
        SELECT application_id INTO l_app_id 
        FROM apex_applications 
        WHERE application_id = 101 OR alias = 'CHATAPP'
        FETCH FIRST 1 ROWS ONLY;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          SELECT application_id INTO l_app_id
          FROM apex_applications
          FETCH FIRST 1 ROWS ONLY;
      END;

      apex_session.create_session (
        p_app_id   => l_app_id,
        p_page_id  => 1,
        p_username => 'AIADMIN'
      );
    END IF;

    -- 9. Call Ollama via APEX_AI.GENERATE
    BEGIN
      p_answer := apex_ai.generate (
        p_service_static_id => 'local_ollama',
        p_prompt            => l_prompt
      );
    EXCEPTION
      WHEN OTHERS THEN
        p_answer := 'An issue occurred while generating the AI response. Please ensure local Ollama service is active. Error: ' || SQLERRM;
        p_sources := NULL;
    END;

    -- 10. Smart Citations: If answer indicates not found or similarity is poor, clear misleading sources
    IF INSTR(LOWER(p_answer), 'could not find') > 0 
       OR INSTR(LOWER(p_answer), 'not available') > 0 
       OR INSTR(LOWER(p_answer), 'not found') > 0
       OR INSTR(LOWER(p_answer), 'not mentioned') > 0
       OR l_min_dist > 0.65
    THEN
      p_sources := NULL;
    END IF;

  END ask_with_sources;

  FUNCTION ask (
    p_question IN VARCHAR2
  ) RETURN CLOB IS
    l_ans CLOB;
    l_src VARCHAR2(1000);
  BEGIN
    ask_with_sources(p_question, l_ans, l_src);
    RETURN l_ans;
  END ask;

END policy_rag_pkg;
/

PROMPT Package POLICY_RAG_PKG compiled successfully.

PROMPT Testing Greeting
DECLARE
  l_ans CLOB;
  l_src VARCHAR2(1000);
BEGIN
  policy_rag_pkg.ask_with_sources(
    p_question => 'Hii',
    p_answer   => l_ans,
    p_sources  => l_src
  );
  dbms_output.put_line('Sources: ' || NVL(l_src, '(none)'));
  dbms_output.put_line('Answer:  ' || l_ans);
END;
/

PROMPT Testing Policy Question
DECLARE
  l_ans CLOB;
  l_src VARCHAR2(1000);
BEGIN
  policy_rag_pkg.ask_with_sources(
    p_question => 'What is the guaranteed response time for a Severity 1 Critical Outage?',
    p_answer   => l_ans,
    p_sources  => l_src
  );
  dbms_output.put_line('Sources: ' || NVL(l_src, '(none)'));
  dbms_output.put_line('Answer:  ' || l_ans);
END;
/

exit;
