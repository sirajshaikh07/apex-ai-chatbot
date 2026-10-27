set serveroutput on linesize 220 pagesize 100
SELECT attribute_sequence, static_id, apexlang_name, attribute_scope
FROM apex_appl_plugin_attributes
WHERE plugin_static_id = 'FILE';
exit;
