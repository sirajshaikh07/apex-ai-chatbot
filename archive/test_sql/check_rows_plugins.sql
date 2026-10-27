set serveroutput on linesize 220 pagesize 100
SELECT plugin_type, static_id, apexlang_name, display_name
FROM apex_appl_plugins;
exit;
