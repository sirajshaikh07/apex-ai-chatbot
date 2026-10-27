CREATE OR REPLACE PROCEDURE approve_user_registration (
    p_request_id IN NUMBER,
    p_admin_user IN VARCHAR2
) AS
    l_user  VARCHAR2(100);
    l_pass  VARCHAR2(255);
    l_name  VARCHAR2(255);
    l_email VARCHAR2(255);
    l_first VARCHAR2(100);
    l_last  VARCHAR2(100);
    l_uid   NUMBER;
    l_ws    VARCHAR2(100);
BEGIN
    SELECT username, password, full_name, email
    INTO   l_user, l_pass, l_name, l_email
    FROM   user_registrations
    WHERE  request_id = p_request_id;

    l_first := NVL(SUBSTR(l_name, 1, INSTR(l_name, ' ') - 1), l_name);
    l_last  := NVL(SUBSTR(l_name, INSTR(l_name, ' ') + 1), 'User');

    BEGIN
      SELECT workspace INTO l_ws FROM apex_workspaces FETCH FIRST 1 ROWS ONLY;
    EXCEPTION WHEN OTHERS THEN
      l_ws := 'AIWORKSPACE';
    END;

    apex_util.set_workspace(l_ws);
    l_uid := apex_util.get_user_id(UPPER(l_user));
    IF l_uid IS NOT NULL THEN
        apex_util.remove_user(p_user_id => l_uid);
    END IF;

    apex_util.create_user(
        p_user_name                    => UPPER(l_user),
        p_first_name                   => l_first,
        p_last_name                    => l_last,
        p_email_address                => l_email,
        p_web_password                 => l_pass,
        p_change_password_on_first_use => 'N'
    );

    UPDATE user_registrations
    SET status = 'APPROVED', reviewed_by = p_admin_user, reviewed_at = SYSTIMESTAMP
    WHERE request_id = p_request_id;
    COMMIT;
END approve_user_registration;
/
SHOW ERRORS PROCEDURE approve_user_registration;
exit;
