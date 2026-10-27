set serveroutput on linesize 220 pagesize 100
SELECT a.attribute_sequence, a.static_id, a.apexlang_name, a.prompt, a.default_value
FROM apex_appl_plugin_attributes a
WHERE a.plugin_static_id = 'FILE'
ORDER BY a.attribute_sequence;
exit;
