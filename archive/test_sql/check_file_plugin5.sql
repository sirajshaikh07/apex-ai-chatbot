set serveroutput on linesize 220 pagesize 100
SELECT plugin_static_id, plugin_name, attribute_sequence, static_id, apexlang_name, prompt, default_value
FROM apex_appl_plugin_attributes
WHERE plugin_static_id LIKE '%FILE%' OR plugin_name LIKE '%File%'
ORDER BY plugin_static_id, attribute_sequence;
exit;
