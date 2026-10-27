set serveroutput on size unlimited feedback off linesize 200
DECLARE
  l_ans CLOB;
  l_src VARCHAR2(1000);
  l_sess NUMBER := 888888;
BEGIN
  -- Turn 1: Siraj tasks
  dbms_output.put_line('=== TURN 1: How many task siraj completed ===');
  enterprise_rag_pkg.ask_with_context(
    p_question   => 'How many task siraj completed',
    p_session_id => l_sess,
    p_user_name  => 'AIDEMO_ADMIN',
    p_answer     => l_ans,
    p_sources    => l_src
  );
  dbms_output.put_line('AI: ' || SUBSTR(l_ans, 1, 1500));

  -- Record Turn 1 in chat history
  INSERT INTO chat_history (session_id, user_name, user_prompt, ai_response, sources)
  VALUES (l_sess, 'AIDEMO_ADMIN', 'How many task siraj completed', l_ans, l_src);
  COMMIT;

  -- Turn 2: Follow-up with pronoun "he"
  dbms_output.put_line('=== TURN 2: how many task he completed in pspcl project ===');
  enterprise_rag_pkg.ask_with_context(
    p_question   => 'how many task he completed in pspcl project',
    p_session_id => l_sess,
    p_user_name  => 'AIDEMO_ADMIN',
    p_answer     => l_ans,
    p_sources    => l_src
  );
  dbms_output.put_line('AI: ' || SUBSTR(l_ans, 1, 1500));

  -- Clean up test session
  DELETE FROM chat_history WHERE session_id = l_sess;
  COMMIT;
END;
/
exit;
