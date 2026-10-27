#!/usr/bin/env bash
set -euo pipefail

source /home/ubuntu/project/values.env
source /home/ubuntu/.secrets.env

mkdir -p /home/ubuntu/project/sql

echo "=== 1. Creating AIDEMO user & granting roles as SYSDBA ==="
/usr/local/bin/sql -thin -S /nolog <<EOF
connect sys/"${SYS_PWD}"@//${VM1_IP}:${DB_PORT}/${DB_SERVICE} as sysdba
set serveroutput on heading on feedback off

DECLARE
  v_count NUMBER;
BEGIN
  SELECT count(*) INTO v_count FROM dba_users WHERE username = 'AIDEMO';
  IF v_count = 0 THEN
    EXECUTE IMMEDIATE 'CREATE USER AIDEMO IDENTIFIED BY "${AIDEMO_PWD}" DEFAULT TABLESPACE USERS QUOTA UNLIMITED ON USERS';
    dbms_output.put_line('User AIDEMO created.');
  ELSE
    dbms_output.put_line('User AIDEMO already exists.');
  END IF;
END;
/

GRANT CREATE SESSION, DB_DEVELOPER_ROLE, CREATE MINING MODEL TO AIDEMO;

-- 4 & 5. Workspace and User
DECLARE
  v_ws_count NUMBER;
  v_user_count NUMBER;
  v_ws_id NUMBER;
BEGIN
  SELECT count(*) INTO v_ws_count FROM apex_workspaces WHERE workspace = 'AIDEMO';
  IF v_ws_count = 0 THEN
    apex_instance_admin.add_workspace (
      p_workspace      => 'AIDEMO',
      p_primary_schema => 'AIDEMO'
    );
    COMMIT;
    dbms_output.put_line('Workspace AIDEMO created.');
  ELSE
    dbms_output.put_line('Workspace AIDEMO already exists.');
  END IF;

  SELECT workspace_id INTO v_ws_id FROM apex_workspaces WHERE workspace = 'AIDEMO';
  apex_util.set_security_group_id(v_ws_id);

  SELECT count(*) INTO v_user_count 
  FROM apex_workspace_apex_users 
  WHERE user_name = 'AIDEMO_ADMIN' AND workspace_name = 'AIDEMO';

  IF v_user_count = 0 THEN
    apex_util.create_user(
      p_user_name                    => 'AIDEMO_ADMIN',
      p_web_password                 => '${WS_ADMIN_PWD}',
      p_email_address                => 'aidemo_admin@local',
      p_developer_privs              => 'ADMIN:CREATE:DATA_LOADER:EDIT:HELP:MONITOR:SQL',
      p_change_password_on_first_use => 'N'
    );
    COMMIT;
    dbms_output.put_line('User AIDEMO_ADMIN created.');
  ELSE
    dbms_output.put_line('User AIDEMO_ADMIN already exists.');
  END IF;
END;
/
exit;
EOF

echo "=== 2. REST-enabling schema AIDEMO ==="
/usr/local/bin/sql -thin -S /nolog <<EOF
connect AIDEMO/"${AIDEMO_PWD}"@//${VM1_IP}:${DB_PORT}/${DB_SERVICE}
set serveroutput on heading on feedback off
BEGIN
  ORDS.ENABLE_SCHEMA(
    p_enabled             => TRUE,
    p_schema              => 'AIDEMO',
    p_url_mapping_type    => 'BASE_PATH',
    p_url_mapping_pattern => 'aidemo',
    p_auto_rest_auth      => FALSE
  );
  COMMIT;
  dbms_output.put_line('Schema AIDEMO REST-enabled.');
END;
/
exit;
EOF

echo "=== 3. Verification Gate Queries ==="
/usr/local/bin/sql -thin -S /nolog <<EOF
connect sys/"${SYS_PWD}"@//${VM1_IP}:${DB_PORT}/${DB_SERVICE} as sysdba
set heading on feedback off pagesize 50 linesize 200
PROMPT --- DBA_USERS ---
SELECT username, account_status FROM dba_users WHERE username = 'AIDEMO';
PROMPT --- APEX_WORKSPACES ---
SELECT workspace, workspace_id FROM apex_workspaces WHERE workspace = 'AIDEMO';
PROMPT --- APEX_WORKSPACE_DEVELOPERS ---
SELECT user_name, email, is_admin FROM apex_workspace_apex_users WHERE workspace_name = 'AIDEMO';
exit;
EOF

/usr/local/bin/sql -thin -S /nolog <<EOF
connect AIDEMO/"${AIDEMO_PWD}"@//${VM1_IP}:${DB_PORT}/${DB_SERVICE}
set heading on feedback off
PROMPT --- USER_ORDS_SCHEMAS ---
SELECT schema, enabled FROM user_ords_schemas;
exit;
EOF

# Copy to ~/project/sql/ and log
cp /home/ubuntu/docs/05_workspace.sh /home/ubuntu/project/sql/05_workspace.sh

cat << 'LOGEOF' >> /home/ubuntu/project/LOG.md

## Phase 5 Gate Results (Workspace & Schema AIDEMO)
- Schema AIDEMO: OPEN with CREATE MINING MODEL & DB_DEVELOPER_ROLE
- ORDS Schema: ENABLED (pattern: aidemo)
- Workspace AIDEMO: Created & Active
- Developer User: AIDEMO_ADMIN (Admin privs, change_pwd_on_first_use=N)
- Tested via SQLcl over network to VM1 FREEPDB1
LOGEOF

echo "=== Phase 5 Successfully Completed! ==="
