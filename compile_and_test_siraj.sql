SET SERVEROUTPUT ON SIZE UNLIMITED;
SET DEFINE OFF;
ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

PROMPT ============================================================
PROMPT 1. COMPILING ENTERPRISE_RAG_PKG
PROMPT ============================================================
@enterprise_rag_pkg.sql

PROMPT ============================================================
PROMPT 2. RUNNING TEST 1: Any pending task of siraj
PROMPT ============================================================
DECLARE
  l_ans CLOB;
  l_src VARCHAR2(1000);
  t0 NUMBER;
  t1 NUMBER;
BEGIN
  t0 := DBMS_UTILITY.GET_TIME;
  enterprise_rag_pkg.ask_with_context(
    p_question => 'Any pending task of siraj',
    p_answer   => l_ans,
    p_sources  => l_src
  );
  t1 := DBMS_UTILITY.GET_TIME;
  DBMS_OUTPUT.PUT_LINE('Latency: ' || ROUND((t1 - t0)*10) || ' ms (' || ROUND((t1 - t0)/100, 1) || ' s)');
  DBMS_OUTPUT.PUT_LINE('Answer:');
  DBMS_OUTPUT.PUT_LINE(SUBSTR(l_ans, 1, 3000));
  DBMS_OUTPUT.PUT_LINE('Sources: ' || l_src);
END;
/

PROMPT ============================================================
PROMPT 3. RUNNING TEST 2: List of task siraj not started
PROMPT ============================================================
DECLARE
  l_ans CLOB;
  l_src VARCHAR2(1000);
  t0 NUMBER;
  t1 NUMBER;
BEGIN
  t0 := DBMS_UTILITY.GET_TIME;
  enterprise_rag_pkg.ask_with_context(
    p_question => 'List of task siraj not started',
    p_answer   => l_ans,
    p_sources  => l_src
  );
  t1 := DBMS_UTILITY.GET_TIME;
  DBMS_OUTPUT.PUT_LINE('Latency: ' || ROUND((t1 - t0)*10) || ' ms (' || ROUND((t1 - t0)/100, 1) || ' s)');
  DBMS_OUTPUT.PUT_LINE('Answer:');
  DBMS_OUTPUT.PUT_LINE(SUBSTR(l_ans, 1, 3000));
  DBMS_OUTPUT.PUT_LINE('Sources: ' || l_src);
END;
/

EXIT;
