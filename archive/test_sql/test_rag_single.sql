set serveroutput on size unlimited feedback off linesize 200
DECLARE
  l_ans CLOB;
  l_src VARCHAR2(1000);
  l_start NUMBER := DBMS_UTILITY.GET_TIME;
BEGIN
  dbms_output.put_line('Calling ask_with_context...');
  enterprise_rag_pkg.ask_with_context(
    p_question   => 'How many projects are there',
    p_session_id => 12345,
    p_user_name  => 'AIDEMO_ADMIN',
    p_answer     => l_ans,
    p_sources    => l_src
  );
  dbms_output.put_line('TIME: ' || ((DBMS_UTILITY.GET_TIME - l_start)*10) || ' ms');
  dbms_output.put_line('ANSWER: ' || SUBSTR(l_ans, 1, 1000));
END;
/
exit;
