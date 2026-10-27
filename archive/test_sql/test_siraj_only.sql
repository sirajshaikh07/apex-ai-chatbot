set serveroutput on
DECLARE
  l_app_id NUMBER := 101;
BEGIN
  apex_session.create_session (
    p_app_id   => l_app_id,
    p_page_id  => 1,
    p_username => 'SIRAJ'
  );
  dbms_output.put_line('User: ' || v('APP_USER'));

  IF apex_authorization.is_authorized('Administration Rights') THEN
    dbms_output.put_line('SIRAJ authorized: TRUE');
  ELSE
    dbms_output.put_line('SIRAJ authorized: FALSE');
  END IF;

  apex_session.delete_session;
END;
/
exit;
