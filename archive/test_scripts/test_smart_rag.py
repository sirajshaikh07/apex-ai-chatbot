import os
import subprocess

sql_input = """set define off serveroutput on linesize 200 feedback on

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
    l_norm_q := TRIM(LOWER(REGEXP_REPLACE(p_question, '[^a-zA-Z0-9 ]', '')));

    -- 1. Fast path for basic greetings
    IF l_norm_q IN ('hi', 'hii', 'hiii', 'hello', 'hey', 'heyy', 'hola', 'namaste', 'greetings') THEN
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

    -- 2. Fast path for gratitude & farewells
    IF l_norm_q IN ('thanks', 'thank you', 'thx', 'thank you so much', 'bye', 'goodbye', 'see you') THEN
      p_answer := 'You are very welcome! Let me know if you need any other assistance. Have a wonderful day!';
      p_sources := NULL;
      RETURN;
    END IF;

    -- 3. In-DB Vector Search across policy chunks
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

exit;
"""

with open("/home/ubuntu/docs/update_rag_smart.sql", "w") as f:
    f.write(sql_input)

print("Compiling smart POLICY_RAG_PKG...")
cmd = ["python3", "/home/ubuntu/docs/run_sql.py", "update_rag_smart.sql"]
p = subprocess.run(cmd, capture_output=True, text=True)
print(p.stdout)
