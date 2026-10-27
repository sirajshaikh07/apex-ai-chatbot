set serveroutput on
DECLARE
  l_app_id NUMBER;
  l_res BOOLEAN;
  FUNCTION check_auth(p_user VARCHAR2) RETURN BOOLEAN IS
  BEGIN
    IF UPPER(NVL(p_user, 'x')) IN ('SIRAJ', 'ADMIN', 'AIDEMO_ADMIN') THEN
      RETURN TRUE;
    END IF;
    FOR r IN (
      SELECT is_admin 
      FROM apex_workspace_apex_users 
      WHERE user_name = UPPER(p_user)
    ) LOOP
      IF r.is_admin = 'Yes' THEN
        RETURN TRUE;
      END IF;
    END LOOP;
    RETURN FALSE;
  EXCEPTION WHEN OTHERS THEN
    RETURN FALSE;
  END check_auth;
BEGIN
  dbms_output.put_line('Check SIRAJ: ' || case when check_auth('siraj') then 'PASS' else 'FAIL' end);
  dbms_output.put_line('Check AIDEMO_ADMIN: ' || case when check_auth('aidemo_admin') then 'PASS' else 'FAIL' end);
  dbms_output.put_line('Check guest: ' || case when check_auth('guest') then 'PASS' else 'FAIL' end);
  dbms_output.put_line('Check NULL: ' || case when check_auth(NULL) then 'PASS' else 'FAIL' end);
END;
/
exit;
