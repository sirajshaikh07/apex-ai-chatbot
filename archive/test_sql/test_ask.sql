set serveroutput on
DECLARE
  l_ans CLOB;
BEGIN
  l_ans := policy_rag_pkg.ask('Hii');
  dbms_output.put_line('Answer: ' || SUBSTR(l_ans, 1, 200));
END;
/
exit;
