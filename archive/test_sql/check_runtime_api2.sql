set serveroutput on linesize 220 pagesize 100
SELECT application_id, runtime_api_usage
FROM apex_applications
WHERE application_id = 101;
exit;
