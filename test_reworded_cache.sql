SET SERVEROUTPUT ON TIMING ON;

DECLARE
  l_ans CLOB;
  l_src VARCHAR2(1000);
  l_msg_id NUMBER;
  l_t0 NUMBER := DBMS_UTILITY.GET_TIME;
BEGIN
  ENTERPRISE_RAG_PKG.ASK_WITH_CONTEXT(
    p_question   => 'How long is the probationary period for new appointments?',
    p_session_id => 777666,
    p_user_name  => 'CACHE_TEST_2',
    p_answer     => l_ans,
    p_sources    => l_src,
    p_msg_id     => l_msg_id
  );
  DBMS_OUTPUT.PUT_LINE('Total Wall Clock Elapsed: ' || ROUND((DBMS_UTILITY.GET_TIME - l_t0) * 10) || 'ms');
  DBMS_OUTPUT.PUT_LINE('Package Execution Time:   ' || ENTERPRISE_RAG_PKG.G_LAST_RESPONSE_TIME_MS || 'ms');
  DBMS_OUTPUT.PUT_LINE('Sources:                  ' || l_src);
  DBMS_OUTPUT.PUT_LINE('Answer Preview:           ' || DBMS_LOB.SUBSTR(l_ans, 200, 1));
END;
/
EXIT;
