set serveroutput on
BEGIN
  FOR r IN (SELECT user_name, is_admin FROM apex_workspace_apex_users) LOOP
    dbms_output.put_line(r.user_name || ' -> is_admin=' || r.is_admin);
  END LOOP;
END;
/
exit;
