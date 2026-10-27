set serveroutput on linesize 220 pagesize 100
SELECT column_name
FROM all_tab_columns
WHERE table_name = 'APEX_APPLICATIONS' AND (column_name LIKE '%API%' OR column_name LIKE '%WORKSPACE%' OR column_name LIKE '%RUNTIME%');

SELECT runtime_api_usage
FROM apex_applications
WHERE application_id = 101;
exit;
