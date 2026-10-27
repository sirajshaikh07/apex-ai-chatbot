SET SERVEROUTPUT ON TIMING ON;

PROMPT =========================================================================
PROMPT Test 1: First Query (Smart Context Budgeting via Ollama)
PROMPT =========================================================================
DECLARE
  l_ans CLOB;
  l_src VARCHAR2(1000);
  l_msg_id NUMBER;
BEGIN
  ENTERPRISE_RAG_PKG.ASK_WITH_CONTEXT(
    p_question   => 'What is the probationary period for new appointments and how long can it be extended?',
    p_session_id => 999111,
    p_user_name  => 'TEST_USER',
    p_answer     => l_ans,
    p_sources    => l_src,
    p_msg_id     => l_msg_id
  );
  DBMS_OUTPUT.PUT_LINE('--- First Turn Response (Time: ' || ENTERPRISE_RAG_PKG.G_LAST_RESPONSE_TIME_MS || 'ms) ---');
  DBMS_OUTPUT.PUT_LINE('Msg ID:  ' || l_msg_id);
  DBMS_OUTPUT.PUT_LINE('Sources: ' || l_src);
  DBMS_OUTPUT.PUT_LINE('Answer:  ' || DBMS_LOB.SUBSTR(l_ans, 300, 1));
END;
/

PROMPT =========================================================================
PROMPT Test 2: Repeat Query (In-Database Semantic Cache Hit - Target: < 50ms!)
PROMPT =========================================================================
DECLARE
  l_ans CLOB;
  l_src VARCHAR2(1000);
  l_msg_id NUMBER;
BEGIN
  ENTERPRISE_RAG_PKG.ASK_WITH_CONTEXT(
    p_question   => 'probation period kitna hai aur kitna extend ho sakta hai?',
    p_session_id => 999222,
    p_user_name  => 'TEST_USER',
    p_answer     => l_ans,
    p_sources    => l_src,
    p_msg_id     => l_msg_id
  );
  DBMS_OUTPUT.PUT_LINE('--- Second Turn (Semantic Cache Hit) ---');
  DBMS_OUTPUT.PUT_LINE('Msg ID:  ' || l_msg_id);
  DBMS_OUTPUT.PUT_LINE('Sources: ' || l_src);
  DBMS_OUTPUT.PUT_LINE('Elapsed: ' || ENTERPRISE_RAG_PKG.G_LAST_RESPONSE_TIME_MS || 'ms');
  DBMS_OUTPUT.PUT_LINE('Answer:  ' || DBMS_LOB.SUBSTR(l_ans, 300, 1));
END;
/

EXIT;
