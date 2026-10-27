SET SERVEROUTPUT ON SIZE UNLIMITED;
SET LINESIZE 250;
ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

DECLARE
  l_ans CLOB;
  l_src VARCHAR2(1000);
BEGIN
  DBMS_OUTPUT.PUT_LINE('========================================================');
  DBMS_OUTPUT.PUT_LINE('Q5: What tasks does Yogita have in C4T?');
  DBMS_OUTPUT.PUT_LINE('========================================================');

  enterprise_rag_pkg.ask_with_context(
    p_question   => 'What tasks does Yogita have in C4T?',
    p_session_id => 10005,
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
