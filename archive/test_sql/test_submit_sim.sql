set serveroutput on
DECLARE
  l_app_id NUMBER := 101;
  l_page_id NUMBER := 2;
  l_status VARCHAR2(20);
BEGIN
  -- 1. Create session as SIRAJ
  apex_session.create_session (
    p_app_id   => l_app_id,
    p_page_id  => l_page_id,
    p_username => 'SIRAJ'
  );

  -- 2. Simulate setting P2_ACTION_REQ_ID = 2
  apex_util.set_session_state('P2_ACTION_REQ_ID', '2');
  dbms_output.put_line('Simulating submit with P2_ACTION_REQ_ID = ' || v('P2_ACTION_REQ_ID'));

  -- 3. Simulate process approve-user
  IF v('P2_ACTION_REQ_ID') IS NOT NULL THEN
    approve_user_registration(TO_NUMBER(v('P2_ACTION_REQ_ID')), v('APP_USER'));
    dbms_output.put_line('Process executed. Success message set.');
  END IF;

  -- 4. Verify user status in user_registrations
  SELECT status INTO l_status FROM user_registrations WHERE request_id = 2;
  dbms_output.put_line('User status in DB is now: ' || l_status);

  -- Reset back to PENDING so user can test in browser
  UPDATE user_registrations SET status = 'PENDING', reviewed_by = NULL, reviewed_at = NULL WHERE request_id = 2;
  apex_util.set_workspace('AIDEMO');
  apex_util.remove_user(p_user_id => apex_util.get_user_id('YOGI'));
  COMMIT;
  dbms_output.put_line('Reset back to PENDING for browser test.');

  apex_session.delete_session;
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('ERROR: ' || SQLERRM);
END;
/
exit;
