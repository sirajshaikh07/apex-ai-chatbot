set pagesize 0 linesize 32000 long 100000 feedback off
SELECT region_name, static_id, template, template_options 
FROM apex_application_page_regions 
WHERE application_id = 101 AND page_id = 1;
exit;
