set pagesize 100 linesize 200 feedback off
SELECT template_name, internal_name 
FROM apex_application_temp_region 
WHERE application_id = 101
ORDER BY template_name;
exit;
