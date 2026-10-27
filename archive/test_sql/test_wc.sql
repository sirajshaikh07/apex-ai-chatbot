set define off serveroutput on size unlimited feedback off linesize 200 pagesize 0 trimout on
DECLARE
  l_ans CLOB;
  l_src VARCHAR2(500);
BEGIN
  enterprise_rag_pkg.ask_with_context(
    p_question   => 'World Cup 2024 kisne jeeta?',
    p_session_id => 88889,
    p_user_name  => 'TESTER',
    p_answer     => l_ans,
    p_sources    => l_src
  );
  dbms_output.put_line('SOURCES: ' || NVL(l_src, 'NONE'));
  dbms_output.put_line('ANSWER: ' || l_ans);
END;
/
exit;
