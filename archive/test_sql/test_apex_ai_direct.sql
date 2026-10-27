set serveroutput on size unlimited feedback off linesize 200
DECLARE
  l_ans CLOB;
  l_start NUMBER := DBMS_UTILITY.GET_TIME;
BEGIN
  IF apex_application.g_flow_id IS NULL THEN
    apex_session.create_session (
      p_app_id   => 101,
      p_page_id  => 1,
      p_username => 'AIDEMO_ADMIN'
    );
  END IF;

  l_ans := apex_ai.generate (
    p_service_static_id => 'local_ollama',
    p_prompt            => 'Say hello in one word.'
  );
  dbms_output.put_line('AI RESPONSE: ' || l_ans);
  dbms_output.put_line('TIME MS: ' || ((DBMS_UTILITY.GET_TIME - l_start)*10));
END;
/
exit;
