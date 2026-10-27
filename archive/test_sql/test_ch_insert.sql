set serveroutput on
DECLARE
  l_cnt NUMBER;
BEGIN
  INSERT INTO chat_history (session_id, user_name, user_prompt, ai_response, sources)
  VALUES (777777, 'ADMIN', 'Test prompt', 'Test response', 'none');
  COMMIT;
  SELECT count(*) INTO l_cnt FROM chat_history WHERE session_id = 777777;
  dbms_output.put_line('Inserted count: ' || l_cnt);
  DELETE FROM chat_history WHERE session_id = 777777;
  COMMIT;
END;
/
exit;
