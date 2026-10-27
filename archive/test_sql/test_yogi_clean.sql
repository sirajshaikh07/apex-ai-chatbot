set serveroutput on
DECLARE
  l_app_id NUMBER := 101;
BEGIN
  apex_session.create_session (p_app_id => l_app_id, p_page_id => 1, p_username => 'YOGI');
  dbms_output.put_line('Direct test - YOGI authorized: ' || case when apex_authorization.is_authorized('Administration Rights') then 'TRUE (Admin)' else 'FALSE (Regular user - PASS)' end);
  apex_session.delete_session;
END;
/
exit;
