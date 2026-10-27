SET SERVEROUTPUT ON TIMING ON;

DECLARE
  l_prompt CLOB;
  l_sources VARCHAR2(1000);
  l_is_cache VARCHAR2(1);
  l_cached_ans CLOB;
  l_cached_msg NUMBER;
BEGIN
  ENTERPRISE_RAG_PKG.BUILD_GROUNDED_PROMPT(
    p_question      => 'What is the policy for medical leave and certificates?',
    p_session_id    => 12345,
    p_user_name     => 'TEST_USER',
    p_prompt        => l_prompt,
    p_sources       => l_sources,
    p_is_cache      => l_is_cache,
    p_cached_answer => l_cached_ans,
    p_cached_msg_id => l_cached_msg
  );

  DBMS_OUTPUT.PUT_LINE('Is Cache: ' || l_is_cache);
  DBMS_OUTPUT.PUT_LINE('Sources:  ' || l_sources);
  IF l_is_cache = 'Y' THEN
    DBMS_OUTPUT.PUT_LINE('Cached Ans: ' || DBMS_LOB.SUBSTR(l_cached_ans, 200, 1));
  ELSE
    DBMS_OUTPUT.PUT_LINE('Prompt Length: ' || DBMS_LOB.GETLENGTH(l_prompt));
    DBMS_OUTPUT.PUT_LINE('Prompt Snippet: ' || DBMS_LOB.SUBSTR(l_prompt, 200, DBMS_LOB.GETLENGTH(l_prompt) - 200));
  END IF;
END;
/
EXIT;
