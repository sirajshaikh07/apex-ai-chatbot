DECLARE
  l_cnt NUMBER;
  l_id NUMBER := 9403999999999999;
BEGIN
  SELECT COUNT(*) INTO l_cnt 
  FROM APEX_260200.WWV_FLOW_PROCESSING 
  WHERE flow_id = 101 AND process_name = 'SUBMIT_FEEDBACK';

  IF l_cnt = 0 THEN
    INSERT INTO APEX_260200.WWV_FLOW_PROCESSING (
      id, flow_id, process_sequence, process_point, process_type,
      process_name, static_id, process_sql_clob, security_group_id, created_by, created_on
    ) VALUES (
      l_id, 101, 10, 'ON_DEMAND', 'NATIVE_PLSQL',
      'SUBMIT_FEEDBACK', 'SUBMIT_FEEDBACK',
      'BEGIN
    enterprise_rag_pkg.submit_feedback(
        p_msg_id            => TO_NUMBER(apex_application.g_x01),
        p_feedback          => apex_application.g_x02,
        p_feedback_category => apex_application.g_x03,
        p_feedback_comment  => apex_application.g_x04
    );
    apex_json.open_object;
    apex_json.write(''status'', ''SUCCESS'');
    apex_json.close_object;
EXCEPTION
    WHEN OTHERS THEN
        apex_json.open_object;
        apex_json.write(''status'', ''ERROR'');
        apex_json.write(''message'', SQLERRM);
        apex_json.close_object;
END;',
      7400144151320570, 'ADMIN', SYSDATE
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Inserted SUBMIT_FEEDBACK application process');
  ELSE
    UPDATE APEX_260200.WWV_FLOW_PROCESSING
    SET process_sql_clob = 'BEGIN
    enterprise_rag_pkg.submit_feedback(
        p_msg_id            => TO_NUMBER(apex_application.g_x01),
        p_feedback          => apex_application.g_x02,
        p_feedback_category => apex_application.g_x03,
        p_feedback_comment  => apex_application.g_x04
    );
    apex_json.open_object;
    apex_json.write(''status'', ''SUCCESS'');
    apex_json.close_object;
EXCEPTION
    WHEN OTHERS THEN
        apex_json.open_object;
        apex_json.write(''status'', ''ERROR'');
        apex_json.write(''message'', SQLERRM);
        apex_json.close_object;
END;'
    WHERE flow_id = 101 AND process_name = 'SUBMIT_FEEDBACK';
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Updated SUBMIT_FEEDBACK application process');
  END IF;
END;
/
EXIT;
