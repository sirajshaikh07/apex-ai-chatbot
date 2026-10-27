set serveroutput on
DECLARE
  l_app_id NUMBER;
  l_res BOOLEAN;
BEGIN
  SELECT application_id INTO l_app_id FROM apex_applications WHERE workspace = 'AIDEMO' FETCH FIRST 1 ROWS ONLY;

  apex_session.create_session (
    p_app_id   => l_app_id,
    p_page_id  => 2,
    p_username => 'SIRAJ'
  );

  BEGIN
    l_res := (UPPER(v('APP_USER')) in ('AIDEMO_ADMIN', 'ADMIN', 'SIRAJ') or apex_acl.is_role_member(p_role_static_id => 'ADMINISTRATOR'));
    dbms_output.put_line('Result with apex_acl: ' || case when l_res then 'TRUE' else 'FALSE' end);
  EXCEPTION WHEN OTHERS THEN
    dbms_output.put_line('Error in auth with apex_acl: ' || SQLERRM);
  END;

  BEGIN
    l_res := (UPPER(v('APP_USER')) in ('AIDEMO_ADMIN', 'ADMIN', 'SIRAJ'));
    dbms_output.put_line('Result simple: ' || case when l_res then 'TRUE' else 'FALSE' end);
  END;
END;
/
exit;
