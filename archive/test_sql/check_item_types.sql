set serveroutput on linesize 220 pagesize 100
SELECT plugin_type, static_id, name, apexlang_name
FROM apex_appl_plugins
WHERE plugin_type = 'ITEM TYPE'
ORDER BY static_id;
exit;
