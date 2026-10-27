set serveroutput on linesize 220 pagesize 100
SELECT v.display_sequence, v.display_value, v.return_value, v.apexlang_name
FROM apex_appl_plugin_attr_values v
JOIN apex_appl_plugin_attributes a ON v.plugin_attribute_id = a.plugin_attribute_id
WHERE a.plugin_static_id = 'FILE' AND a.static_id = 'storage_type'
ORDER BY v.display_sequence;
exit;
