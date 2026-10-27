set serveroutput on
DECLARE
  l_app_id NUMBER := 101;
BEGIN
  -- Test 1: AIADMIN
  apex_session.create_session (p_app_id => l_app_id, p_page_id => 1, p_username => 'AIADMIN');
  dbms_output.put_line('AIADMIN authorized: ' || case when apex_authorization.is_authorized('Administration Rights') then 'TRUE (PASS - Admin)' else 'FALSE' end);
  apex_session.delete_session;

  -- Test 2: SIRAJ
  apex_session.create_session (p_app_id => l_app_id, p_page_id => 1, p_username => 'SIRAJ');
  dbms_output.put_line('SIRAJ authorized: ' || case when apex_authorization.is_authorized('Administration Rights') then 'TRUE (PASS - Admin)' else 'FALSE' end);
  apex_session.delete_session;

  -- Test 3: YOGI
  apex_session.create_session (p_app_id => l_app_id, p_page_id => 1, p_username => 'YOGI');
  dbms_output.put_line('YOGI authorized: ' || case when apex_authorization.is_authorized('Administration Rights') then 'TRUE (FAIL - Normal user should not be admin)' else 'FALSE (PASS - Regular user)' end);
  apex_session.delete_session;
END;
/
exit;
