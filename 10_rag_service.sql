set define off serveroutput on linesize 200 feedback on

PROMPT ========================================================
PROMPT   Phase 10: RAG Pipeline Package and Enterprise REST API
PROMPT ========================================================

PROMPT [1] Creating POLICY_RAG_PKG specification and body...

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
    l_is_policy  BOOLEAN := FALSE;
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

    -- 3. Detect Gratitude & Closings
    IF l_norm_q IN ('thanks', 'thank you', 'thx', 'thank you so much', 'bye', 'goodbye', 'see you', 'ok', 'okay', 'great') THEN
      p_answer := 'You are very welcome! Let me know if you need any other policy or compliance assistance. Have a great day!';
      p_sources := NULL;
      RETURN;
    END IF;

    -- 4. In-DB Vector Search for Top-2 relevant chunks in Oracle 26ai
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

    -- 4. Check if question contains policy-related intent or keywords
    IF REGEXP_LIKE(l_norm_q, 'sla|outage|leave|vacation|holiday|encrypt|security|password|expense|travel|reimburse|escalat|severit|support|policy|rule|claim|flight|hotel|war room|incident')
       OR l_min_dist < 0.48
    THEN
      l_is_policy := TRUE;
    END IF;

    -- 5. Dynamic Smart Prompt for Ollama
    l_prompt := 'You are an intelligent, polite, and helpful Enterprise AI Assistant.' || CHR(10) ||
                'You assist employees with company policies, SLAs, leaves, IT security, expenses, and general conversational inquiries.' || CHR(10) || CHR(10) ||
                'Company Policy Reference Context:' || CHR(10) ||
                NVL(l_context, 'No policy context.') || CHR(10) || CHR(10) ||
                'Instructions:' || CHR(10) ||
                '1. General & Conversational Questions: If the user asks casual questions, conversational questions, pleasantries, questions about yourself, or general greetings (e.g. "How are you?", "Where are you from?", "Who are you?", "What can you do?", "What is your purpose?"), respond naturally, warmly, professionally, and concisely as the enterprise AI assistant.' || CHR(10) ||
                '2. Policy & Compliance Questions: If the user asks about company policies, SLAs, leaves, expenses, or guidelines, answer accurately and directly based on the policy context above. If a specific policy detail is not present in the context, politely inform the user that this specific detail is not covered in the current documentation and suggest contacting HR or IT.' || CHR(10) ||
                '3. Tone: Be concise, clear, and professional.' || CHR(10) || CHR(10) ||
                'User: ' || p_question || CHR(10) ||
                'Assistant:';

    -- 6. Ensure APEX session
    IF apex_application.g_flow_id IS NULL THEN
      SELECT application_id INTO l_app_id 
      FROM apex_applications 
      WHERE workspace = 'AIDEMO' 
      FETCH FIRST 1 ROWS ONLY;

      apex_session.create_session (
        p_app_id   => l_app_id,
        p_page_id  => 1,
        p_username => 'AIDEMO_ADMIN'
      );
    END IF;

    -- 7. Generate via Ollama
    p_answer := apex_ai.generate (
      p_service_static_id => 'local_ollama',
      p_prompt            => l_prompt
    );

    -- 8. Smart Citation: Only show source if policy context was actually used
    IF NOT l_is_policy
       OR INSTR(LOWER(p_answer), 'not covered') > 0
       OR INSTR(LOWER(p_answer), 'not found') > 0
       OR INSTR(LOWER(p_answer), 'not available') > 0
       OR l_min_dist > 0.60
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

PROMPT [2] Testing POLICY_RAG_PKG.ASK in PL/SQL session...
DECLARE
  l_ans CLOB;
  l_src VARCHAR2(1000);
BEGIN
  policy_rag_pkg.ask_with_sources(
    p_question => 'What is the guaranteed response time for a Severity 1 Critical Outage?',
    p_answer   => l_ans,
    p_sources  => l_src
  );
  dbms_output.put_line('Sources: ' || l_src);
  dbms_output.put_line('Answer:  ' || l_ans);
END;
/

PROMPT [3] Configuring ORDS REST API Endpoint: POST /ords/aidemo/api/chat ...
BEGIN
  -- Enable AIDEMO schema for REST
  ORDS.ENABLE_SCHEMA(
    p_enabled             => TRUE,
    p_schema              => 'AIDEMO',
    p_url_mapping_type    => 'BASE_PATH',
    p_url_mapping_pattern => 'aidemo',
    p_auto_rest_auth      => FALSE
  );

  -- Drop existing module if present to re-create clean
  BEGIN
    ORDS.DELETE_MODULE(p_module_name => 'enterprise_ai');
  EXCEPTION WHEN OTHERS THEN NULL;
  END;

  -- Create enterprise_ai module
  ORDS.DEFINE_MODULE(
    p_module_name    => 'enterprise_ai',
    p_base_path      => 'api/',
    p_items_per_page => 0,
    p_status         => 'PUBLISHED'
  );

  -- Define template /api/chat
  ORDS.DEFINE_TEMPLATE(
    p_module_name    => 'enterprise_ai',
    p_pattern        => 'chat'
  );

  -- Define POST handler on /api/chat
  ORDS.DEFINE_HANDLER(
    p_module_name    => 'enterprise_ai',
    p_pattern        => 'chat',
    p_method         => 'POST',
    p_source_type    => ORDS.SOURCE_TYPE_PLSQL,
    p_source         => '
DECLARE
  l_body_clob CLOB;
  l_question  VARCHAR2(4000);
  l_answer    CLOB;
  l_sources   VARCHAR2(1000);
  l_response  CLOB;
  l_offset    NUMBER := 1;
  l_chunk     NUMBER := 32000;
  l_len       NUMBER;
BEGIN
  l_body_clob := :body;
  
  APEX_JSON.PARSE(l_body_clob);
  l_question := APEX_JSON.GET_VARCHAR2(p_path => ''question'');
  
  IF l_question IS NULL THEN
    OWA_UTIL.STATUS_LINE(400, ''Bad Request'');
    HTP.P(''{"error": "Missing required JSON parameter: question"}'');
    RETURN;
  END IF;

  POLICY_RAG_PKG.ASK_WITH_SOURCES(
    p_question => l_question,
    p_answer   => l_answer,
    p_sources  => l_sources
  );

  OWA_UTIL.MIME_HEADER(''application/json'', TRUE);

  SELECT JSON_OBJECT(
    ''status''   VALUE ''success'',
    ''question'' VALUE l_question,
    ''answer''   VALUE l_answer,
    ''sources''  VALUE l_sources
    RETURNING CLOB
  ) INTO l_response FROM dual;

  l_len := DBMS_LOB.GETLENGTH(l_response);
  WHILE l_offset <= l_len LOOP
    HTP.PRN(DBMS_LOB.SUBSTR(l_response, l_chunk, l_offset));
    l_offset := l_offset + l_chunk;
  END LOOP;
END;
'
  );

  -- Bind :body as CLOB parameter
  ORDS.DEFINE_PARAMETER(
    p_module_name        => 'enterprise_ai',
    p_pattern            => 'chat',
    p_method             => 'POST',
    p_name               => 'body',
    p_bind_variable_name => 'body',
    p_source_type        => 'BODY',
    p_param_type         => 'CLOB',
    p_access_method      => 'IN'
  );

  COMMIT;
END;
/

PROMPT ORDS REST API Endpoint configured: /ords/aidemo/api/chat
exit;
