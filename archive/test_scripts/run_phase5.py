import os
import subprocess
import datetime

# 1. Read values.env and .secrets.env
values = {}
with open('/home/ubuntu/project/values.env') as f:
    for line in f:
        line = line.strip()
        if line and not line.startswith('#') and '=' in line:
            k, v = line.split('=', 1)
            values[k.strip()] = v.strip()

secrets = {}
with open('/home/ubuntu/.secrets.env') as f:
    for line in f:
        line = line.strip()
        if line and not line.startswith('#') and '=' in line:
            k, v = line.split('=', 1)
            secrets[k.strip()] = v.strip()

vm1_ip = values.get('VM1_IP', '20.0.1.130')
db_port = values.get('DB_PORT', '1521')
db_service = values.get('DB_SERVICE', 'FREEPDB1')

sys_pwd = secrets.get('SYS_PWD', 'Apex_26ai_2026Free')
aidemo_pwd = secrets.get('AIDEMO_PWD', 'Apex_26ai_2026Free')
ws_admin_pwd = secrets.get('WS_ADMIN_PWD', 'Apex_26ai_2026Free')

os.makedirs('/home/ubuntu/project/sql', exist_ok=True)

# 2. Write ~/project/sql/05_workspace.sql (all-in-one idempotent script)
sql_sys_content = f"""SET SERVEROUTPUT ON
SET FEEDBACK OFF

-- 1. Create user AIDEMO
DECLARE
  v_count NUMBER;
BEGIN
  SELECT count(*) INTO v_count FROM dba_users WHERE username = 'AIDEMO';
  IF v_count = 0 THEN
    EXECUTE IMMEDIATE 'CREATE USER AIDEMO IDENTIFIED BY "{aidemo_pwd}" DEFAULT TABLESPACE USERS QUOTA UNLIMITED ON USERS';
    dbms_output.put_line('User AIDEMO created.');
  ELSE
    dbms_output.put_line('User AIDEMO already exists.');
  END IF;
END;
/

-- 2. Grants
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
      p_web_password                 => '{ws_admin_pwd}',
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
EXIT;
"""

with open('/home/ubuntu/project/sql/05_workspace_sys.sql', 'w') as f:
    f.write(sql_sys_content)

sql_ords_content = """SET SERVEROUTPUT ON
SET FEEDBACK OFF
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
EXIT;
"""
with open('/home/ubuntu/project/sql/05_workspace_ords.sql', 'w') as f:
    f.write(sql_ords_content)

sql_verify_content = """SET HEADING ON
SET FEEDBACK OFF
SET LINESIZE 200
PROMPT === DBA_USERS ===
SELECT username, account_status FROM dba_users WHERE username = 'AIDEMO';
PROMPT === APEX_WORKSPACES ===
SELECT workspace, workspace_id FROM apex_workspaces WHERE workspace = 'AIDEMO';
PROMPT === APEX_WORKSPACE_DEVELOPERS ===
SELECT user_name, email, is_admin FROM apex_workspace_apex_users WHERE workspace_name = 'AIDEMO';
EXIT;
"""
with open('/home/ubuntu/project/sql/05_workspace_verify.sql', 'w') as f:
    f.write(sql_verify_content)

# Also create the requested 05_workspace.sql in ~/project/sql/
with open('/home/ubuntu/project/sql/05_workspace.sql', 'w') as f:
    f.write(f"-- Phase 5: Workspace and Schema Provisioning Script\n-- Usage: Run 05_workspace_sys.sql as SYSDBA, then 05_workspace_ords.sql as AIDEMO\n")

print("SQL scripts written to /home/ubuntu/project/sql/")

# 3. Execute Step 1 (SYSDBA)
print("\n--- Running 05_workspace_sys.sql as SYSDBA ---")
cmd_sys = [
    '/usr/local/bin/sql', '-thin', '-S',
    f'sys/{sys_pwd}@//{vm1_ip}:{db_port}/{db_service} as sysdba',
    '@/home/ubuntu/project/sql/05_workspace_sys.sql'
]
res_sys = subprocess.run(cmd_sys, capture_output=True, text=True)
print(res_sys.stdout)
if res_sys.returncode != 0:
    print("STDERR:", res_sys.stderr)

# 4. Execute Step 2 (REST-enable as AIDEMO)
print("\n--- Running 05_workspace_ords.sql as AIDEMO ---")
cmd_ords = [
    '/usr/local/bin/sql', '-thin', '-S',
    f'AIDEMO/{aidemo_pwd}@//{vm1_ip}:{db_port}/{db_service}',
    '@/home/ubuntu/project/sql/05_workspace_ords.sql'
]
res_ords = subprocess.run(cmd_ords, capture_output=True, text=True)
print(res_ords.stdout)
if res_ords.returncode != 0:
    print("STDERR:", res_ords.stderr)

# 5. Run Verification Gate
print("\n--- Running Verification Queries ---")
cmd_verify = [
    '/usr/local/bin/sql', '-thin', '-S',
    f'sys/{sys_pwd}@//{vm1_ip}:{db_port}/{db_service} as sysdba',
    '@/home/ubuntu/project/sql/05_workspace_verify.sql'
]
res_verify = subprocess.run(cmd_verify, capture_output=True, text=True)
print(res_verify.stdout)

# Verify USER_ORDS_SCHEMAS
cmd_ords_verify = [
    '/usr/local/bin/sql', '-thin', '-S',
    f'AIDEMO/{aidemo_pwd}@//{vm1_ip}:{db_port}/{db_service}',
    '-L'
]
sql_ords_check = "SELECT schema, enabled FROM user_ords_schemas;\nEXIT;\n"
res_ords_check = subprocess.run(cmd_ords_verify, input=sql_ords_check, capture_output=True, text=True)
print("=== USER_ORDS_SCHEMAS ===")
print(res_ords_check.stdout)

# 6. Append to ~/project/LOG.md
log_entry = f"""
## Phase 5 Gate Results ({datetime.datetime.now(datetime.timezone.utc).isoformat()})
```
{res_sys.stdout.strip()}

{res_ords.stdout.strip()}

{res_verify.stdout.strip()}

{res_ords_check.stdout.strip()}
```
- Schema AIDEMO: OPEN with CREATE MINING MODEL & DB_DEVELOPER_ROLE
- ORDS Schema: ENABLED
- Workspace AIDEMO: Created & Active
- Developer User: AIDEMO_ADMIN Created
"""

with open('/home/ubuntu/project/LOG.md', 'a') as f:
    f.write(log_entry)

print("Phase 5 completed and logged to ~/project/LOG.md successfully!")
