set serveroutput on
DECLARE
  l_app_id NUMBER := 101;
  l_page_id NUMBER := 2;
  l_auth_name VARCHAR2(255);
  l_auth_ok BOOLEAN;
BEGIN
  -- 1. Create APEX session as regular user
  apex_session.create_session (
    p_app_id   => l_app_id,
    p_page_id  => l_page_id,
    p_username => 'REGULAR_USER'
  );
  dbms_output.put_line('Step 1: Session created for ' || v('APP_USER'));

  SELECT authorization_scheme
  INTO   l_auth_name
  FROM   apex_application_pages
  WHERE  application_id = l_app_id AND page_id = l_page_id;

  l_auth_ok := apex_authorization.is_authorized(l_auth_name);
  IF l_auth_ok THEN
    dbms_output.put_line('Step 3: User is AUTHORIZED');
  ELSE
    dbms_output.put_line('Step 3: Access DENIED as expected for regular user!');
  END IF;

  apex_session.delete_session;
END;
/
exit;
