SET SERVEROUTPUT ON TIMING ON;

PROMPT =========================================================================
PROMPT Test: Semantic Cache Hit Verification (Target: < 50ms!)
PROMPT =========================================================================
DECLARE
  l_ans CLOB;
  l_src VARCHAR2(1000);
  l_msg_id NUMBER;
  l_t0 NUMBER := DBMS_UTILITY.GET_TIME;
  l_elapsed NUMBER;
BEGIN
  ENTERPRISE_RAG_PKG.ASK_WITH_CONTEXT(
    p_question   => 'What is the probationary period for new appointments and how long can it be extended?',
    p_session_id => 888777,
    p_user_name  => 'CACHE_TEST',
    p_answer     => l_ans,
    p_sources    => l_src,
    p_msg_id     => l_msg_id
  );
  l_elapsed := ROUND((DBMS_UTILITY.GET_TIME - l_t0) * 10);
  DBMS_OUTPUT.PUT_LINE('--- Cache Test Result ---');
  DBMS_OUTPUT.PUT_LINE('Total Wall Clock Elapsed: ' || l_elapsed || 'ms');
  DBMS_OUTPUT.PUT_LINE('Package Execution Time:   ' || ENTERPRISE_RAG_PKG.G_LAST_RESPONSE_TIME_MS || 'ms');
  DBMS_OUTPUT.PUT_LINE('Sources:                  ' || l_src);
  DBMS_OUTPUT.PUT_LINE('Answer Preview:           ' || DBMS_LOB.SUBSTR(l_ans, 200, 1));
END;
/
EXIT;
