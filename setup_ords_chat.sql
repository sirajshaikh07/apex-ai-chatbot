set define off serveroutput on linesize 200 feedback on

PROMPT === 1. Enabling Schema AIDEMO ===
BEGIN
  ORDS.ENABLE_SCHEMA(
    p_enabled             => TRUE,
    p_schema              => 'AIDEMO',
    p_url_mapping_type    => 'BASE_PATH',
    p_url_mapping_pattern => 'aidemo',
    p_auto_rest_auth      => FALSE
  );
  COMMIT;
END;
/

PROMPT === 2. Defining ORDS Module enterprise_ai ===
BEGIN
  BEGIN
    ORDS.DELETE_MODULE(p_module_name => 'enterprise_ai');
    COMMIT;
  EXCEPTION WHEN OTHERS THEN NULL;
  END;

  ORDS.DEFINE_MODULE(
    p_module_name    => 'enterprise_ai',
    p_base_path      => 'api/',
    p_items_per_page => 0,
    p_status         => 'PUBLISHED'
  );

  ORDS.DEFINE_TEMPLATE(
    p_module_name    => 'enterprise_ai',
    p_pattern        => 'chat'
  );

  ORDS.DEFINE_HANDLER(
    p_module_name    => 'enterprise_ai',
    p_pattern        => 'chat',
    p_method         => 'POST',
    p_source_type    => ORDS.SOURCE_TYPE_PLSQL,
    p_source         => '
DECLARE
  l_question   VARCHAR2(4000);
  l_session_id NUMBER;
  l_user_name  VARCHAR2(100);
  l_answer     CLOB;
  l_sources    VARCHAR2(1000);
  l_msg_id     NUMBER;
  l_response   CLOB;
  l_offset     NUMBER := 1;
  l_chunk      NUMBER := 32000;
  l_len        NUMBER;
BEGIN
  APEX_JSON.PARSE(:body_text);
  l_question   := APEX_JSON.GET_VARCHAR2(p_path => ''question'');
  l_session_id := APEX_JSON.GET_NUMBER(p_path => ''session_id'');
  l_user_name  := NVL(APEX_JSON.GET_VARCHAR2(p_path => ''user_name''), ''API_USER'');
  
  IF l_question IS NULL THEN
    OWA_UTIL.STATUS_LINE(400, ''Bad Request'');
    HTP.P(''{"error": "Missing required JSON parameter: question"}'');
    RETURN;
  END IF;

  -- Maintain session for multi-turn conversational memory
  IF l_session_id IS NULL OR l_session_id = 0 THEN
    l_session_id := ROUND(DBMS_RANDOM.VALUE(100000, 999999));
  END IF;

  -- Call primary context & memory-aware RAG procedure
  ENTERPRISE_RAG_PKG.ASK_WITH_CONTEXT(
    p_question   => l_question,
    p_session_id => l_session_id,
    p_user_name  => l_user_name,
    p_answer     => l_answer,
    p_sources    => l_sources,
    p_msg_id     => l_msg_id
  );

  OWA_UTIL.MIME_HEADER(''application/json'', TRUE);

  SELECT JSON_OBJECT(
    ''status''       VALUE ''success'',
    ''msg_id''       VALUE l_msg_id,
    ''session_id''   VALUE l_session_id,
    ''user_name''    VALUE l_user_name,
    ''question''     VALUE l_question,
    ''answer''       VALUE l_answer,
    ''sources''      VALUE l_sources,
    ''response_ms''  VALUE ENTERPRISE_RAG_PKG.G_LAST_RESPONSE_TIME_MS
    RETURNING CLOB
  ) INTO l_response FROM dual;

  l_len := DBMS_LOB.GETLENGTH(l_response);
  WHILE l_offset <= l_len LOOP
    HTP.PRN(DBMS_LOB.SUBSTR(l_response, l_chunk, l_offset));
    l_offset := l_offset + l_chunk;
  END LOOP;
END;
'
  );

  COMMIT;
  dbms_output.put_line('Module enterprise_ai with POST /api/chat created successfully.');
END;
/

PROMPT === 3. Verifying Registered ORDS Module and Handlers ===
SELECT name, uri_prefix, status FROM user_ords_modules WHERE name = 'enterprise_ai';
SELECT module_name, uri_template, method, source_type FROM user_ords_services WHERE module_name = 'enterprise_ai';

exit;
