set serveroutput on heading on feedback on linesize 200
BEGIN
  -- Grant connect privilege to APEX internal engine schema (APEX_260200)
  DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
    host           => '20.0.1.39',
    lower_port     => 5000,
    upper_port     => 6000,
    ace            => xs$ace_type(
                        privilege_list => xs$name_list('connect'),
                        principal_name => 'APEX_260200',
                        principal_type => xs_acl.ptype_db
                      )
  );

  -- Grant connect privilege to AIDEMO
  DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
    host           => '20.0.1.39',
    lower_port     => 5000,
    upper_port     => 6000,
    ace            => xs$ace_type(
                        privilege_list => xs$name_list('connect'),
                        principal_name => 'AIDEMO',
                        principal_type => xs_acl.ptype_db
                      )
  );
  COMMIT;
  dbms_output.put_line('ACL for APEX_260200 and AIDEMO on 20.0.1.39:5000-6000 granted successfully.');
END;
/
exit;
