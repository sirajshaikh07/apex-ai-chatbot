set feedback on linesize 200 pagesize 100
SELECT attribute_sequence, attribute_identifier, prompt, default_value
FROM apex_appl_plugin_attributes
WHERE plugin_name = 'NATIVE_FILE'
ORDER BY attribute_sequence;
exit;
