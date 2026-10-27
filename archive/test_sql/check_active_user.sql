set serveroutput on linesize 200
SELECT apex_user, page_id, view_date, error_message
FROM apex_workspace_activity_log
WHERE workspace_name = 'AIDEMO'
ORDER BY view_date DESC
FETCH FIRST 10 ROWS ONLY;
exit;
