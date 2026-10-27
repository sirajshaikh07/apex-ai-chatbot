set serveroutput on linesize 200 pagesize 50
SELECT apex_user, page_id, view_timestamp, error_message, error_on_component_type, error_on_component_name
FROM apex_workspace_activity_log
WHERE workspace = 'AIDEMO'
ORDER BY view_timestamp DESC
FETCH FIRST 10 ROWS ONLY;
exit;
