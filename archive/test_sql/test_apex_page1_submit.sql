set serveroutput on size unlimited feedback off linesize 200
DECLARE
  l_ans CLOB;
  l_src VARCHAR2(1000);
  l_session_id NUMBER;
BEGIN
  -- 1. Create APEX session as AIDEMO_ADMIN on App 101 Page 1
  apex_session.create_session (
    p_app_id   => 101,
    p_page_id  => 1,
    p_username => 'AIDEMO_ADMIN'
  );
  l_session_id := apex_application.g_instance;
  dbms_output.put_line('Active APEX Session: ' || l_session_id);

  -- 2. Simulate Turn 1: Siraj tasks
  enterprise_rag_pkg.ask_with_context(
    p_question   => 'How many task siraj completed',
    p_session_id => l_session_id,
    p_user_name  => 'AIDEMO_ADMIN',
    p_answer     => l_ans,
    p_sources    => l_src
  );
  INSERT INTO chat_history (session_id, user_name, user_prompt, ai_response, sources)
  VALUES (l_session_id, 'AIDEMO_ADMIN', 'How many task siraj completed', l_ans, l_src);
  COMMIT;
  dbms_output.put_line('Turn 1 Answer: ' || SUBSTR(l_ans, 1, 200));

  -- 3. Simulate Turn 2: Follow-up pronoun question in PSPCL
  enterprise_rag_pkg.ask_with_context(
    p_question   => 'how many task he completed in pspcl project',
    p_session_id => l_session_id,
    p_user_name  => 'AIDEMO_ADMIN',
    p_answer     => l_ans,
    p_sources    => l_src
  );
  INSERT INTO chat_history (session_id, user_name, user_prompt, ai_response, sources)
  VALUES (l_session_id, 'AIDEMO_ADMIN', 'how many task he completed in pspcl project', l_ans, l_src);
  COMMIT;
  dbms_output.put_line('Turn 2 Answer: ' || SUBSTR(l_ans, 1, 250));

  -- Clean up test records
  DELETE FROM chat_history WHERE session_id = l_session_id;
  COMMIT;
END;
/
exit;
