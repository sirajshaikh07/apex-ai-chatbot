set serveroutput on size unlimited feedback off linesize 200 pagesize 0 trimout on
DECLARE
  PROCEDURE run_q(p_q IN VARCHAR2) IS
    l_ans CLOB;
    l_src VARCHAR2(500);
  BEGIN
    dbms_output.put_line('----------------------------------------------------');
    dbms_output.put_line('QUESTION: ' || p_q);
    enterprise_rag_pkg.ask_with_context(
      p_question   => p_q,
      p_session_id => 88888,
      p_user_name  => 'TEST_ADMIN',
      p_answer     => l_ans,
      p_sources    => l_src
    );
    dbms_output.put_line('SOURCES: ' || NVL(l_src, 'NONE'));
    dbms_output.put_line('ANSWER:');
    dbms_output.put_line(l_ans);
  END;
BEGIN
  run_q('Who is Safa Himmatkha Pathan?');
  run_q('What is her education and date of birth?');
  run_q('What are the contact details and address?');
  run_q('Who is Siraj?');
END;
/
exit;
