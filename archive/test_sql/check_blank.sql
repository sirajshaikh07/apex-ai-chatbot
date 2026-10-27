set pagesize 100 linesize 200 feedback off
SELECT template_name, internal_name, theme_id
FROM apex_application_temp_region 
WHERE application_id = 101 AND internal_name LIKE 'BLANK%';
exit;
