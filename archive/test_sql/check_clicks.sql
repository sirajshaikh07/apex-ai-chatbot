set serveroutput on linesize 220 pagesize 100
SELECT view_timestamp, apex_user, page_id, request_value, error_message
FROM apex_workspace_activity_log
WHERE workspace = 'AIDEMO'
ORDER BY view_timestamp DESC
FETCH FIRST 10 ROWS ONLY;
exit;
