set serveroutput on size unlimited feedback off linesize 200
DECLARE
  l_ans CLOB;
  l_src VARCHAR2(1000);
BEGIN
  enterprise_rag_pkg.ask_with_context(
    p_question   => 'Who is Safa Himmatkha Pathan',
    p_session_id => 999111,
    p_user_name  => 'SIRAJ',
    p_answer     => l_ans,
    p_sources    => l_src
  );
  dbms_output.put_line('ANSWER: ' || l_ans);
  dbms_output.put_line('SOURCES: ' || l_src);
END;
/
exit;
