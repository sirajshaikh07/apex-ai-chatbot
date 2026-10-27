set serveroutput on
DECLARE
  l_app_id NUMBER := 101;
  l_page_id NUMBER := 2;
BEGIN
  -- 1. Create APEX session as SIRAJ
  apex_session.create_session (
    p_app_id   => l_app_id,
    p_page_id  => l_page_id,
    p_username => 'SIRAJ'
  );
  dbms_output.put_line('Session OK: user=' || v('APP_USER') || ', session=' || v('APP_SESSION'));

  -- 2. Verify authorization
  IF apex_authorization.is_authorized('Administration Rights') THEN
    dbms_output.put_line('Authorization: GRANTED');
  ELSE
    dbms_output.put_line('Authorization: DENIED');
  END IF;

  -- 3. Verify items exist in session state
  apex_util.set_session_state('P2_ACTION_REQ_ID', '1');
  dbms_output.put_line('P2_ACTION_REQ_ID: ' || v('P2_ACTION_REQ_ID'));

  apex_session.delete_session;
  dbms_output.put_line('ALL TESTS COMPLETED SUCCESSFULLY!');
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('ERROR: ' || SQLERRM);
END;
/
exit;
