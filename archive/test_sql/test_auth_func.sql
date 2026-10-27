set serveroutput on
DECLARE
  l_app_id NUMBER;
  l_res BOOLEAN;
  FUNCTION check_admin(p_user VARCHAR2) RETURN BOOLEAN IS
  BEGIN
    IF UPPER(NVL(p_user, 'x')) IN ('AIDEMO_ADMIN', 'ADMIN', 'SIRAJ') THEN
      RETURN TRUE;
    END IF;
    FOR r IN (
      SELECT is_admin 
      FROM apex_workspace_users 
      WHERE user_name = UPPER(p_user)
    ) LOOP
      IF r.is_admin = 'Yes' THEN
        RETURN TRUE;
      END IF;
    END LOOP;
    RETURN FALSE;
  EXCEPTION WHEN OTHERS THEN
    RETURN FALSE;
  END check_admin;
BEGIN
  IF check_admin('SIRAJ') THEN
    dbms_output.put_line('SIRAJ is ADMIN: TRUE');
  ELSE
    dbms_output.put_line('SIRAJ is ADMIN: FALSE');
  END IF;

  IF check_admin('admin') THEN
    dbms_output.put_line('admin is ADMIN: TRUE');
  ELSE
    dbms_output.put_line('admin is ADMIN: FALSE');
  END IF;

  IF check_admin('random_user') THEN
    dbms_output.put_line('random_user is ADMIN: TRUE');
  ELSE
    dbms_output.put_line('random_user is ADMIN: FALSE');
  END IF;
END;
/
exit;
