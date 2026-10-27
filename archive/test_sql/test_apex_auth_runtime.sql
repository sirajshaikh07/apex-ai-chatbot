set serveroutput on
DECLARE
  l_auth BOOLEAN;
BEGIN
  -- Create APEX session for user SIRAJ on App 101 Page 2
  apex_session.create_session (
    p_app_id   => 101,
    p_page_id  => 2,
    p_username => 'SIRAJ'
  );

  dbms_output.put_line('Session created for: ' || v('APP_USER'));

  l_auth := apex_authorization.is_authorized('administration-rights');
  IF l_auth THEN
    dbms_output.put_line('TEST PASSED: SIRAJ is AUTHORIZED for administration-rights!');
  ELSE
    dbms_output.put_line('TEST FAILED: SIRAJ is NOT authorized!');
  END IF;

  apex_session.delete_session;
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('ERROR: ' || SQLERRM);
END;
/
exit;
