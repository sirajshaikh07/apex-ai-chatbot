set serveroutput on
DECLARE
  l_ans CLOB;
  l_src VARCHAR2(1000);
BEGIN
  policy_rag_pkg.ask_with_sources(
    p_question => 'Hii',
    p_answer   => l_ans,
    p_sources  => l_src
  );
  dbms_output.put_line('=== TEST: Hii ===');
  dbms_output.put_line('Sources: [' || l_src || ']');
  dbms_output.put_line('Answer:' || CHR(10) || l_ans);
END;
/

DECLARE
  l_ans CLOB;
  l_src VARCHAR2(1000);
BEGIN
  policy_rag_pkg.ask_with_sources(
    p_question => 'What is the guaranteed response time for a Severity 1 Critical Outage?',
    p_answer   => l_ans,
    p_sources  => l_src
  );
  dbms_output.put_line('=== TEST: Severity 1 ===');
  dbms_output.put_line('Sources: [' || l_src || ']');
  dbms_output.put_line('Answer:' || CHR(10) || l_ans);
END;
/
exit;
