set serveroutput on linesize 200 pagesize 100
SELECT attribute_sequence, attribute_identifier, prompt, default_value
FROM apex_appl_plugin_std_attrs
WHERE plugin_type = 'ITEM TYPE'
ORDER BY attribute_sequence;

SELECT attribute_sequence, attribute_identifier, prompt, default_value
FROM apex_appl_plugin_attributes
WHERE plugin_name = 'NATIVE_FILE' OR internal_name = 'NATIVE_FILE'
ORDER BY attribute_sequence;
exit;
