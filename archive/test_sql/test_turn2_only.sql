set serveroutput on size unlimited feedback off linesize 200
DECLARE
  l_ans CLOB;
  l_src VARCHAR2(1000);
  l_start NUMBER := DBMS_UTILITY.GET_TIME;
  l_sess NUMBER := 888888;
BEGIN
  -- Insert previous turn
  DELETE FROM chat_history WHERE session_id = l_sess;
  INSERT INTO chat_history (session_id, user_name, user_prompt, ai_response, sources)
  VALUES (l_sess, 'AIDEMO_ADMIN', 'How many task siraj completed', 'Siraj has completed 8 tasks in the C4T project.', 'team_hierarchy (1).txt');
  COMMIT;

  dbms_output.put_line('Calling Turn 2...');
  enterprise_rag_pkg.ask_with_context(
    p_question   => 'how many task he completed in pspcl project',
    p_session_id => l_sess,
    p_user_name  => 'AIDEMO_ADMIN',
    p_answer     => l_ans,
    p_sources    => l_src
  );
  dbms_output.put_line('TIME: ' || ((DBMS_UTILITY.GET_TIME - l_start)*10) || ' ms');
  dbms_output.put_line('ANSWER: ' || SUBSTR(l_ans, 1, 1000));

  DELETE FROM chat_history WHERE session_id = l_sess;
  COMMIT;
END;
/
exit;
