SET SERVEROUTPUT ON SIZE UNLIMITED;
SET LINESIZE 250;

ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

DECLARE
  l_ans CLOB;
  l_src VARCHAR2(1000);
BEGIN
  DBMS_OUTPUT.PUT_LINE('========================================================');
  DBMS_OUTPUT.PUT_LINE('TEST: Give me title of all task siraj completed');
  DBMS_OUTPUT.PUT_LINE('========================================================');

  enterprise_rag_pkg.ask_with_context(
    p_question   => 'Give me title of all task siraj completed',
    p_session_id => 998877,
    p_user_name  => 'ADMIN',
    p_answer     => l_ans,
    p_sources    => l_src
  );

  DBMS_OUTPUT.PUT_LINE('SOURCES: ' || l_src);
  DBMS_OUTPUT.PUT_LINE('ANSWER:');
  DBMS_OUTPUT.PUT_LINE(l_ans);
END;
/
EXIT;
