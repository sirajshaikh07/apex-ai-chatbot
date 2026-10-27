set serveroutput on linesize 220 pagesize 100
SELECT DISTINCT plugin_static_id, plugin_name
FROM apex_appl_plugin_attributes;
exit;
