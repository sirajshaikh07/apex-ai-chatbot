set pagesize 100 linesize 200 feedback off
SELECT display_name, apexlang_name, static_id 
FROM apex_appl_plugins 
WHERE plugin_type = 'ITEM TYPE'
ORDER BY display_name;
exit;
