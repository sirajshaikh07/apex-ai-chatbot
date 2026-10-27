set serveroutput on
DECLARE
  l_req_id NUMBER := 2;
BEGIN
  -- Test approve_user_registration
  approve_user_registration(l_req_id, 'SIRAJ');
  dbms_output.put_line('Approval procedure executed successfully!');
  
  -- Check user created in APEX
  apex_util.set_workspace('AIDEMO');
  dbms_output.put_line('User ID in APEX: ' || apex_util.get_user_id('YOGI'));
  
  -- Reset back to PENDING for the user to test live
  UPDATE user_registrations SET status = 'PENDING', reviewed_by = NULL, reviewed_at = NULL WHERE request_id = l_req_id;
  apex_util.remove_user(p_user_id => apex_util.get_user_id('YOGI'));
  COMMIT;
  dbms_output.put_line('Reset back to PENDING successfully.');
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('ERROR in approval: ' || SQLERRM);
END;
/
exit;
