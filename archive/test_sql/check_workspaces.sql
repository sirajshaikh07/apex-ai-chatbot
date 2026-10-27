set serveroutput on linesize 200 pagesize 100
SELECT workspace, workspace_id FROM apex_workspaces;
SELECT workspace_name, user_name, email, is_admin FROM apex_workspace_apex_users;
exit;
