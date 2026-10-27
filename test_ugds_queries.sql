SET SERVEROUTPUT ON SIZE UNLIMITED;
SET DEFINE OFF;
ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

DECLARE
  l_ans1 CLOB;
  l_src1 VARCHAR2(1000);
  l_ans2 CLOB;
  l_src2 VARCHAR2(1000);
  t0 NUMBER;
  t1 NUMBER;
  t2 NUMBER;
BEGIN
  DBMS_OUTPUT.PUT_LINE('============================================================');
  DBMS_OUTPUT.PUT_LINE('TEST 1: Any pending task of siraj');
  DBMS_OUTPUT.PUT_LINE('============================================================');
  t0 := DBMS_UTILITY.GET_TIME;
  
  enterprise_rag_pkg.ask_with_context(
    p_question => 'Any pending task of siraj',
    p_answer   => l_ans1,
    p_sources  => l_src1
  );
  t1 := DBMS_UTILITY.GET_TIME;
  DBMS_OUTPUT.PUT_LINE('Latency: ' || ROUND((t1 - t0)*10) || ' ms');
  DBMS_OUTPUT.PUT_LINE('Answer:');
  DBMS_OUTPUT.PUT_LINE(SUBSTR(l_ans1, 1, 2000));
  DBMS_OUTPUT.PUT_LINE('Sources: ' || l_src1);

  DBMS_OUTPUT.PUT_LINE('============================================================');
  DBMS_OUTPUT.PUT_LINE('TEST 2: List of task siraj not started');
  DBMS_OUTPUT.PUT_LINE('============================================================');
  enterprise_rag_pkg.ask_with_context(
    p_question => 'List of task siraj not started',
    p_answer   => l_ans2,
    p_sources  => l_src2
  );
  t2 := DBMS_UTILITY.GET_TIME;
  DBMS_OUTPUT.PUT_LINE('Latency: ' || ROUND((t2 - t1)*10) || ' ms');
  DBMS_OUTPUT.PUT_LINE('Answer:');
  DBMS_OUTPUT.PUT_LINE(SUBSTR(l_ans2, 1, 2000));
  DBMS_OUTPUT.PUT_LINE('Sources: ' || l_src2);
  DBMS_OUTPUT.PUT_LINE('============================================================');
END;
/
EXIT;
