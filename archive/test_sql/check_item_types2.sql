set serveroutput on linesize 220 pagesize 100
SELECT static_id, apexlang_name, display_name
FROM apex_appl_plugins
WHERE plugin_type = 'Item Type'
ORDER BY static_id;
exit;
