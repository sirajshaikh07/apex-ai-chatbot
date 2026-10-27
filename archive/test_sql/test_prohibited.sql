set serveroutput on
DECLARE
  l_app_id NUMBER := 101;
  l_page_id NUMBER := 2;
BEGIN
  apex_session.create_session (
    p_app_id   => l_app_id,
    p_page_id  => l_page_id,
    p_username => 'SIRAJ'
  );

  dbms_output.put_line('Workspace is already: ' || v('WORKSPACE_ID'));

  -- Test 1: calling apex_util.set_workspace
  BEGIN
    apex_util.set_workspace('AIDEMO');
    dbms_output.put_line('Test 1: set_workspace OK');
  EXCEPTION WHEN OTHERS THEN
    dbms_output.put_line('Test 1: set_workspace FAILED: ' || SQLERRM);
  END;

  -- Test 2: calling apex_util.get_user_id without set_workspace
  BEGIN
    dbms_output.put_line('Test 2: get_user_id: ' || apex_util.get_user_id('SIRAJ'));
  EXCEPTION WHEN OTHERS THEN
    dbms_output.put_line('Test 2: get_user_id FAILED: ' || SQLERRM);
  END;

  -- Test 3: calling apex_util.create_user
  BEGIN
    apex_util.create_user(
        p_user_name                    => 'TEST_CALL',
        p_first_name                   => 'Test',
        p_last_name                    => 'Call',
        p_email_address                => 'test@example.com',
        p_web_password                 => 'TempPassword123!',
        p_change_password_on_first_use => 'N'
    );
    dbms_output.put_line('Test 3: create_user OK');
    apex_util.remove_user(p_user_id => apex_util.get_user_id('TEST_CALL'));
  EXCEPTION WHEN OTHERS THEN
    dbms_output.put_line('Test 3: create_user FAILED: ' || SQLERRM);
  END;

  apex_session.delete_session;
END;
/
exit;
