set serveroutput on
DECLARE
  l_auth BOOLEAN;
  l_res BOOLEAN;
BEGIN
  apex_session.create_session (
    p_app_id   => 101,
    p_page_id  => 2,
    p_username => 'SIRAJ'
  );

  dbms_output.put_line('v(APP_USER) = ' || v('APP_USER'));

  -- Run the PL/SQL body directly
  BEGIN
    IF UPPER(NVL(v('APP_USER'), 'x')) IN ('AIDEMO_ADMIN', 'ADMIN', 'SIRAJ') THEN
      l_res := TRUE;
    ELSE
      l_res := FALSE;
    END IF;
    dbms_output.put_line('Direct PL/SQL evaluation: ' || case when l_res then 'TRUE' else 'FALSE' end);
  END;

  -- Test by static_id
  l_auth := apex_authorization.is_authorized('administration-rights');
  dbms_output.put_line('is_authorized(administration-rights): ' || case when l_auth then 'TRUE' else 'FALSE' end);

  -- Test by name
  l_auth := apex_authorization.is_authorized('Administration Rights');
  dbms_output.put_line('is_authorized(Administration Rights): ' || case when l_auth then 'TRUE' else 'FALSE' end);

  -- Test page 2 authorization
  l_auth := apex_authorization.is_authorized(p_authorization_name => NULL);
  dbms_output.put_line('is_authorized(NULL): ' || case when l_auth then 'TRUE' else 'FALSE' end);

  apex_session.delete_session;
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('ERROR: ' || SQLERRM);
END;
/
exit;
