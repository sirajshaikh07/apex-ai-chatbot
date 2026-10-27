SET SERVEROUTPUT ON SIZE UNLIMITED;
ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

DECLARE
  l_raw  VARCHAR2(1000) := 'Q1: How long is the probationary period for new appointments, and by how much can it be extended?';
  l_res  VARCHAR2(4000);
  l_proj VARCHAR2(50);
  l_user VARCHAR2(100);
  l_cnt  BOOLEAN;
  l_search_q VARCHAR2(4000);
  l_clean_q  VARCHAR2(2000);
  l_token1   VARCHAR2(100);
  l_token2   VARCHAR2(100);
  l_token3   VARCHAR2(100);
BEGIN
  -- Replicate the steps inside ask_with_context
  -- 1. resolve_query
  enterprise_rag_pkg.resolve_query(
    p_raw_question   => l_raw,
    p_session_id     => NULL,
    p_resolved_query => l_res,
    p_detected_proj  => l_proj,
    p_detected_user  => l_user,
    p_is_proj_count  => l_cnt
  );
  DBMS_OUTPUT.PUT_LINE('Resolved query:    ' || l_res);
  DBMS_OUTPUT.PUT_LINE('Detected project:  ' || NVL(l_proj, '(none)'));
  DBMS_OUTPUT.PUT_LINE('Detected person:   ' || NVL(l_user, '(none)'));

  -- 2. resolve_hinglish
  l_search_q := enterprise_rag_pkg.resolve_hinglish(l_res);
  DBMS_OUTPUT.PUT_LINE('Search query:      ' || l_search_q);

  -- 3. Token extraction
  l_clean_q := REGEXP_REPLACE(UPPER(l_search_q), '[^A-Z0-9 ]', ' ');
  l_clean_q := REGEXP_REPLACE(l_clean_q, '\b(WHAT|WHEN|WHERE|WHICH|WHO|WHOM|WHOSE|WHY|HOW|THE|IS|ARE|WAS|WERE|AM|AN|A|IN|ON|AT|TO|FOR|OF|WITH|BY|FROM|ABOUT|TELL|ME|GIVE|SHOW|CAN|YOU|PLEASE|PERSON|DETAILS|DATA|INFO|INFORMATION)\b', ' ');
  l_clean_q := TRIM(REGEXP_REPLACE(l_clean_q, '\s+', ' '));
  l_token1  := REGEXP_SUBSTR(l_clean_q, '[^ ]+', 1, 1);
  l_token2  := REGEXP_SUBSTR(l_clean_q, '[^ ]+', 1, 2);
  l_token3  := REGEXP_SUBSTR(l_clean_q, '[^ ]+', 1, 3);
  DBMS_OUTPUT.PUT_LINE('Clean Q:           ' || l_clean_q);
  DBMS_OUTPUT.PUT_LINE('Token 1:           ' || NVL(l_token1, '(none)'));
  DBMS_OUTPUT.PUT_LINE('Token 2:           ' || NVL(l_token2, '(none)'));
  DBMS_OUTPUT.PUT_LINE('Token 3:           ' || NVL(l_token3, '(none)'));
END;
/
EXIT;
