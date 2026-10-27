set serveroutput on size unlimited feedback off linesize 4000 trimout on
DECLARE
  l_ans CLOB;
  l_src VARCHAR2(1000);
  l_start NUMBER := DBMS_UTILITY.GET_TIME;
BEGIN
  -- Insert mock history
  
        INSERT INTO chat_history (session_id, user_name, user_prompt, ai_response, sources)
        VALUES (900002, 'EVAL_USER', 'How many task siraj completed', 'Siraj completed 8 tasks in C4T.', 'test_history');
        
  COMMIT;

  enterprise_rag_pkg.ask_with_context(
    p_question   => 'how many task he completed in pspcl project',
    p_session_id => 900002,
    p_user_name  => 'EVAL_USER',
    p_answer     => l_ans,
    p_sources    => l_src
  );

  dbms_output.put_line('=== EVAL RESULT ===');
  dbms_output.put_line('TIME_MS: ' || ROUND((DBMS_UTILITY.GET_TIME - l_start)*10));
  dbms_output.put_line('SOURCES: ' || NVL(l_src, 'NONE'));
  dbms_output.put_line('ANSWER_BEGIN');
  dbms_output.put_line(l_ans);
  dbms_output.put_line('ANSWER_END');

  -- Clean session history
  DELETE FROM chat_history WHERE session_id = 900002;
  COMMIT;
END;
/
exit;
