set serveroutput on
DECLARE
  l_uid NUMBER;
BEGIN
  apex_util.set_workspace('AIDEMO');
  l_uid := apex_util.get_user_id('SIRAJ');
  IF l_uid IS NOT NULL THEN
    apex_util.remove_user(p_user_id => l_uid);
    dbms_output.put_line('Removed existing SIRAJ user.');
  END IF;

  apex_util.create_user(
    p_user_name                    => 'SIRAJ',
    p_first_name                   => 'Siraj',
    p_last_name                    => 'Admin',
    p_email_address                => 'siraj@example.com',
    p_web_password                 => 'siraj',
    p_developer_privs              => 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
    p_change_password_on_first_use => 'N'
  );
  dbms_output.put_line('Successfully created user SIRAJ with password siraj!');
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('Error creating user: ' || SQLERRM);
END;
/
exit;
