set serveroutput on
DECLARE
  l_app_id NUMBER := 101;
  l_page_id NUMBER := 2;
  l_status VARCHAR2(20);
  l_uid NUMBER;
BEGIN
  apex_session.create_session (
    p_app_id   => l_app_id,
    p_page_id  => l_page_id,
    p_username => 'SIRAJ'
  );

  apex_util.set_session_state('P2_ACTION_REQ_ID', '2');
  dbms_output.put_line('P2_ACTION_REQ_ID is set to ' || v('P2_ACTION_REQ_ID'));

  IF v('P2_ACTION_REQ_ID') IS NOT NULL THEN
    approve_user_registration(TO_NUMBER(v('P2_ACTION_REQ_ID')), v('APP_USER'));
    dbms_output.put_line('Approval executed successfully!');
  END IF;

  SELECT status INTO l_status FROM user_registrations WHERE request_id = 2;
  dbms_output.put_line('User status in DB is now: ' || l_status);

  -- Reset back to PENDING for the user to test in browser
  UPDATE user_registrations SET status = 'PENDING', reviewed_by = NULL, reviewed_at = NULL WHERE request_id = 2;
  apex_util.set_workspace('AIDEMO');
  l_uid := apex_util.get_user_id('YOGI');
  IF l_uid IS NOT NULL THEN
    apex_util.remove_user(p_user_id => l_uid);
  END IF;
  COMMIT;
  dbms_output.put_line('Reset back to PENDING for user test.');

  apex_session.delete_session;
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('ERROR: ' || SQLERRM);
END;
/
exit;
