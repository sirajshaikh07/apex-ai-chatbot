SET SERVEROUTPUT ON SIZE UNLIMITED;
SET DEFINE OFF;
ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

PROMPT ============================================================
PROMPT 1. COMPILING ENTERPRISE_RAG_PKG
PROMPT ============================================================
@enterprise_rag_pkg.sql

PROMPT ============================================================
PROMPT 2. RUNNING LIVE TEST ON USER PROBATION QUESTION
PROMPT ============================================================
DECLARE
  l_ans CLOB;
  l_src VARCHAR2(1000);
  t0 NUMBER;
  t1 NUMBER;
BEGIN
  t0 := DBMS_UTILITY.GET_TIME;
  enterprise_rag_pkg.ask_with_context(
    p_question   => 'Q1: How long is the probationary period for new appointments, and by how much can it be extended?',
    p_session_id => 9999,
    p_user_name  => 'ADMIN',
    p_answer     => l_ans,
    p_sources    => l_src
  );
  t1 := DBMS_UTILITY.GET_TIME;
  DBMS_OUTPUT.PUT_LINE('Latency: ' || ROUND((t1 - t0)*10) || ' ms (' || ROUND((t1 - t0)/100, 1) || ' s)');
  DBMS_OUTPUT.PUT_LINE('Sources: ' || NVL(l_src, '(none)'));
  DBMS_OUTPUT.PUT_LINE('Answer:');
  DBMS_OUTPUT.PUT_LINE(SUBSTR(l_ans, 1, 3000));
END;
/
EXIT;
