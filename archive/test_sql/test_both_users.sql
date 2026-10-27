set serveroutput on
DECLARE
  l_app_id NUMBER := 101;
  l_auth_name VARCHAR2(100);
BEGIN
  -- Get authorization scheme name for admin-kb menu entry
  SELECT authorization_scheme INTO l_auth_name
  FROM apex_application_list_entries
  WHERE application_id = l_app_id AND entry_text LIKE 'Knowledge Base%';

  -- Test 1: User YOGI
  apex_session.create_session (
    p_app_id   => l_app_id,
    p_page_id  => 1,
    p_username => 'YOGI'
  );
  dbms_output.put_line('User: ' || v('APP_USER'));
  IF apex_authorization.is_authorized(l_auth_name) THEN
    dbms_output.put_line('Menu entry visible: YES (FAIL)');
  ELSE
    dbms_output.put_line('Menu entry visible: NO (PASS - Hidden for regular user yogi!)');
  END IF;
  apex_session.delete_session;

  -- Test 2: User SIRAJ
  apex_session.create_session (
    p_app_id   => l_app_id,
    p_page_id  => 1,
    p_username => 'SIRAJ'
  );
  dbms_output.put_line('User: ' || v('APP_USER'));
  IF apex_authorization.is_authorized(l_auth_name) THEN
    dbms_output.put_line('Menu entry visible: YES (PASS - Visible for Admin siraj!)');
  ELSE
    dbms_output.put_line('Menu entry visible: NO (FAIL)');
  END IF;
  apex_session.delete_session;

END;
/
exit;
