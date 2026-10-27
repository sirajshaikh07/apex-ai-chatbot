SET DEFINE OFF;
SET SERVEROUTPUT ON;
ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

-- 1. Create ENTERPRISE_TASKS table if not exists
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

-- 2. Populate All Tasks Assigned to Siraj from all_app_data.txt
BEGIN
  -- Completed Tasks (18 Tasks)
  INSERT INTO enterprise_tasks (task_id, task_name, project_code, assignee, status, is_done, deadline, priority, source_doc_id)
  VALUES ('i062532047844', 'PSPCL APP', 'PSPCL', 'Siraj', 'DONE', 'Y', '2026-09-16', 'high', 141);

  INSERT INTO enterprise_tasks (task_id, task_name, project_code, assignee, status, is_done, deadline, priority, source_doc_id)
  VALUES ('i062700807879', 'PSPCL Documentation Update', 'PSPCL', 'Siraj', 'DONE', 'Y', '2026-09-21', 'med', 141);

  INSERT INTO enterprise_tasks (task_id, task_name, project_code, assignee, status, is_done, deadline, priority, source_doc_id)
  VALUES ('i062807967655', 'DC DR Clone Configurations for C4T Tenancy', 'PSPCL', 'Siraj', 'DONE', 'Y', '2026-09-20', 'med', 141);

  INSERT INTO enterprise_tasks (task_id, task_name, project_code, assignee, status, is_done, deadline, priority, source_doc_id)
  VALUES ('i114713727002', 'Connect PSPCL DB in Analytics', 'PSPCL', 'Siraj', 'DONE', 'Y', '2026-10-08', 'med', 141);

  INSERT INTO enterprise_tasks (task_id, task_name, project_code, assignee, status, is_done, deadline, priority, source_doc_id)
  VALUES ('i114632261881', 'Documentation Networking for DR', 'C4T', 'Siraj', 'DONE', 'Y', '2026-09-29', 'med', 141);

  INSERT INTO enterprise_tasks (task_id, task_name, project_code, assignee, status, is_done, deadline, priority, source_doc_id)
  VALUES ('i113344095226', 'WAF+ LB removal', 'C4T', 'Siraj', 'DONE', 'Y', '2026-09-28', 'med', 141);

  INSERT INTO enterprise_tasks (task_id, task_name, project_code, assignee, status, is_done, deadline, priority, source_doc_id)
  VALUES ('i120449647520', 'DR VM creation', 'C4T', 'Siraj', 'DONE', 'Y', '2026-09-28', 'med', 141);

  INSERT INTO enterprise_tasks (task_id, task_name, project_code, assignee, status, is_done, deadline, priority, source_doc_id)
  VALUES ('i200738826643', 'PSPCL PG Dump', 'PSPCL Analytics', 'Siraj', 'DONE', 'Y', '2026-11-06', 'med', 141);

  INSERT INTO enterprise_tasks (task_id, task_name, project_code, assignee, status, is_done, deadline, priority, source_doc_id)
  VALUES ('i100344978390', 'DCs VM CREATIONS IN DR', 'C4T', 'Siraj', 'DONE', 'Y', '2026-09-28', 'med', 141);

  INSERT INTO enterprise_tasks (task_id, task_name, project_code, assignee, status, is_done, deadline, priority, source_doc_id)
  VALUES ('i100344978391', 'Create a Load Balancer in DR C4T', 'C4T', 'Siraj', 'DONE', 'Y', '2026-10-09', 'med', 141);

  INSERT INTO enterprise_tasks (task_id, task_name, project_code, assignee, status, is_done, deadline, priority, source_doc_id)
  VALUES ('i065730668733', 'Enable Compute Instance Run Command', 'C4T', 'Siraj', 'DONE', 'Y', '2026-10-16', 'low', 141);

  INSERT INTO enterprise_tasks (task_id, task_name, project_code, assignee, status, is_done, deadline, priority, source_doc_id)
  VALUES ('i065730668734', 'Get Query From Yogita And Run On Pspcl Analytics', 'PSPCL Analytics', 'Siraj', 'DONE', 'Y', '2026-10-08', 'med', 141);

  INSERT INTO enterprise_tasks (task_id, task_name, project_code, assignee, status, is_done, deadline, priority, source_doc_id)
  VALUES ('i072658186041', 'Enable Compute Instance Run Command for all PSPCL Instances .', 'PSPCL', 'Siraj', 'DONE', 'Y', '2026-10-20', 'med', 141);

  INSERT INTO enterprise_tasks (task_id, task_name, project_code, assignee, status, is_done, deadline, priority, source_doc_id)
  VALUES ('i072658186043', 'Configuring C4T NPCL_GASGRID_AI VMs With new Pem Keys', 'C4T', 'Siraj', 'DONE', 'Y', '2026-10-12', 'high', 141);

  INSERT INTO enterprise_tasks (task_id, task_name, project_code, assignee, status, is_done, deadline, priority, source_doc_id)
  VALUES ('i083101706295', 'Vulnerability Scanning Enable', 'C4T', 'Siraj', 'DONE', 'Y', '2026-10-21', 'med', 141);

  INSERT INTO enterprise_tasks (task_id, task_name, project_code, assignee, status, is_done, deadline, priority, source_doc_id)
  VALUES ('i085646087746', 'Tenancy Onboarding', 'ARCON', 'Siraj', 'DONE', 'Y', '2026-10-20', 'med', 141);

  INSERT INTO enterprise_tasks (task_id, task_name, project_code, assignee, status, is_done, deadline, priority, source_doc_id)
  VALUES ('i052239132741', 'ARCON SUMMARY', 'ARCON', 'Siraj', 'DONE', 'Y', '2026-10-26', 'high', 141);

  INSERT INTO enterprise_tasks (task_id, task_name, project_code, assignee, status, is_done, deadline, priority, source_doc_id)
  VALUES ('i072559233132', 'share the detailed analysis on regular alerts on COPA DB & CPOA HES on c4t group.', 'C4T', 'Siraj', 'DONE', 'Y', '2026-10-26', 'med', 141);

  -- Open / In-Progress Tasks (8 Tasks)
  INSERT INTO enterprise_tasks (task_id, task_name, project_code, assignee, status, is_done, deadline, priority, source_doc_id)
  VALUES ('i185950006050', 'PSPCL Daily Reporting', 'PSPCL', 'Siraj', 'IN_PROGRESS', 'N', '2026-10-26', 'med', 141);

  INSERT INTO enterprise_tasks (task_id, task_name, project_code, assignee, status, is_done, deadline, priority, source_doc_id)
  VALUES ('i120340723242', 'ARCON Daily Reporting', 'ARCON', 'Siraj', 'IN_PROGRESS', 'N', '2026-10-19', 'med', 141);

  INSERT INTO enterprise_tasks (task_id, task_name, project_code, assignee, status, is_done, deadline, priority, source_doc_id)
  VALUES ('i061148067683', 'Autonomous database in PSPCL PROD make it 24*7 available', 'PSPCL', 'Siraj', 'NOT_STARTED', 'N', '2026-10-26', 'med', 141);

  INSERT INTO enterprise_tasks (task_id, task_name, project_code, assignee, status, is_done, deadline, priority, source_doc_id)
  VALUES ('i172135347054', 'Research about Oracle Apex', 'Apex LLM', 'Siraj', 'NOT_STARTED', 'N', '2026-10-27', 'med', 141);

  INSERT INTO enterprise_tasks (task_id, task_name, project_code, assignee, status, is_done, deadline, priority, source_doc_id)
  VALUES ('i172212167814', 'In Test Compartment create take a VM and deploy Oracle 26ai on the same', 'Apex LLM', 'Siraj', 'NOT_STARTED', 'N', '2026-10-28', 'med', 141);

  INSERT INTO enterprise_tasks (task_id, task_name, project_code, assignee, status, is_done, deadline, priority, source_doc_id)
  VALUES ('i060807307783', 'Research on how we deploy Oracle APEX on separate VM in same compartment and connect the DB to it.', 'Apex LLM', 'Siraj', 'NOT_STARTED', 'N', '2026-10-29', 'med', 141);

  INSERT INTO enterprise_tasks (task_id, task_name, project_code, assignee, status, is_done, deadline, priority, source_doc_id)
  VALUES ('i060904697629', 'Host a local LLM and link it to Oracle APEX and DB', 'Apex LLM', 'Siraj', 'NOT_STARTED', 'N', '2026-11-02', 'med', 141);

  INSERT INTO enterprise_tasks (task_id, task_name, project_code, assignee, status, is_done, deadline, priority, source_doc_id)
  VALUES ('i061000183193', 'Post that create a agentic ai that can chat with content available in database', 'Apex LLM', 'Siraj', 'NOT_STARTED', 'N', '2026-11-04', 'med', 141);

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Successfully inserted 26 tasks for Siraj into ENTERPRISE_TASKS table.');
END;
/

EXIT;
