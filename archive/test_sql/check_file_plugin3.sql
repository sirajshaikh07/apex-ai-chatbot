set serveroutput on linesize 220 pagesize 100
SELECT attribute_sequence, static_id, apexlang_name, prompt, default_value
FROM apex_appl_plugin_attributes
WHERE plugin_static_id = 'NATIVE_FILE'
ORDER BY attribute_sequence;
exit;
