set serveroutput on linesize 200 pagesize 100
SELECT application_id, application_name, alias, workspace, workspace_id
FROM apex_applications;
exit;
