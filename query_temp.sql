set pagesize 100 linesize 200 feedback off
SELECT template_name, static_id, internal_name 
FROM apex_application_temp_region 
WHERE application_id = 101 AND (internal_name LIKE 'BLANK%' OR internal_name = 'STANDARD');
exit;
