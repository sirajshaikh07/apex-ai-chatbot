set serveroutput on size unlimited feedback off linesize 200 pagesize 0 trimout on
DECLARE
  l_ans CLOB;
  l_src VARCHAR2(500);
BEGIN
  enterprise_rag_pkg.ask_with_context(
    p_question   => 'Who is Rohit Labade and what is his education and placement details?',
    p_session_id => 33333,
    p_user_name  => 'ADMIN',
    p_answer     => l_ans,
    p_sources    => l_src
  );
  dbms_output.put_line('SOURCES: ' || NVL(l_src, 'NONE'));
  dbms_output.put_line('ANSWER:');
  dbms_output.put_line(l_ans);
END;
/
exit;
