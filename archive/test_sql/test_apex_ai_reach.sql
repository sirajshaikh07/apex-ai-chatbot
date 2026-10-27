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

  BEGIN
    l_ans := apex_ai.generate (
      p_service_static_id => 'local_ollama',
      p_prompt            => 'Reply with OK'
    );
    dbms_output.put_line('SUCCESS: ' || l_ans);
  EXCEPTION
    WHEN OTHERS THEN
      dbms_output.put_line('ERROR: ' || SQLERRM);
  END;
END;
/
exit;
