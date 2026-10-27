set serveroutput on
DECLARE
  l_ans CLOB;
BEGIN
  l_ans := policy_rag_pkg.answer_policy_question('Hello');
  dbms_output.put_line('Greeting test: ' || SUBSTR(l_ans, 1, 150));
  
  l_ans := policy_rag_pkg.answer_policy_question('What is the vacation policy?');
  dbms_output.put_line('Question test: ' || SUBSTR(l_ans, 1, 150));
END;
/
exit;
