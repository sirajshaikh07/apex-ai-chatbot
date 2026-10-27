import re
import json

sql_script = """SET DEFINE OFF;
SET SERVEROUTPUT ON;
ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

-- 1. Create or recreate ENTERPRISE_TASKS table
DECLARE
  v_cnt NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_cnt FROM user_tables WHERE table_name = 'ENTERPRISE_TASKS';
  IF v_cnt > 0 THEN
    EXECUTE IMMEDIATE 'DROP TABLE enterprise_tasks CASCADE CONSTRAINTS';
  END IF;

  EXECUTE IMMEDIATE '
    CREATE TABLE enterprise_tasks (
      task_id       VARCHAR2(50) PRIMARY KEY,
      task_name     VARCHAR2(500) NOT NULL,
      project_code  VARCHAR2(50),
      assignee      VARCHAR2(100),
      status        VARCHAR2(20),
      is_done       CHAR(1) DEFAULT ''N'',
      deadline      VARCHAR2(50),
      priority      VARCHAR2(50),
      source_doc_id NUMBER
    )';
  DBMS_OUTPUT.PUT_LINE('Created table ENTERPRISE_TASKS');
END;
/
"""

# Let's read all_app_data.txt from sql_run.log
with open("/home/ubuntu/docs/sql_run.log", "r", encoding="utf-8", errors="ignore") as f:
    text = f.read()

# Extract items list
blocks = re.split(r'\{\s*"id":', text)
tasks = []

for b in blocks:
    id_m = re.match(r'\s*"([^"]+)"', b)
    if not id_m:
        continue
    tid = id_m.group(1)
    
    name_m = re.search(r'"name":\s*"([^"]+)"', b)
    assignee_m = re.search(r'"assignee":\s*"([^"]+)"', b)
    done_m = re.search(r'"done":\s*(true|false)', b)
    status_m = re.search(r'"status":\s*"([^"]+)"', b)
    pid_m = re.search(r'"pid":\s*"([^"]+)"', b)
    dl_m = re.search(r'"dl":\s*"([^"]+)"', b)
    prio_m = re.search(r'"priority":\s*"([^"]+)"', b)
    
    if name_m and assignee_m:
        name = name_m.group(1).replace("'", "''")
        assignee = assignee_m.group(1)
        done = "Y" if (done_m and done_m.group(1) == "true") or (status_m and status_m.group(1) == "dn") else "N"
        status = "DONE" if done == "Y" else ("IN_PROGRESS" if (status_m and status_m.group(1) == "ip") else "NOT_STARTED")
        pid = pid_m.group(1) if pid_m else ""
        dl = dl_m.group(1) if dl_m else ""
        prio = prio_m.group(1) if prio_m else ""
        
        tasks.append((tid, name, pid, assignee, status, done, dl, prio))

print(f"Extracted {len(tasks)} tasks from all_app_data.txt")

# Generate insert statements
insert_stmts = ["BEGIN\n"]
for tid, name, pid, assignee, status, done, dl, prio in tasks:
    insert_stmts.append(
        f"  INSERT INTO enterprise_tasks (task_id, task_name, project_code, assignee, status, is_done, deadline, priority, source_doc_id) "
        f"VALUES ('{tid}', '{name}', '{pid}', '{assignee}', '{status}', '{done}', '{dl}', '{prio}', 141);\n"
    )
insert_stmts.append("  COMMIT;\n  DBMS_OUTPUT.PUT_LINE('Inserted " + str(len(tasks)) + " tasks into ENTERPRISE_TASKS');\nEND;\n/\nEXIT;\n")

with open("/home/ubuntu/docs/load_enterprise_tasks.sql", "w", encoding="utf-8") as out:
    out.write(sql_script + "".join(insert_stmts))

print("Created /home/ubuntu/docs/load_enterprise_tasks.sql")
