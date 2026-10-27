set serveroutput on linesize 220 pagesize 100
SELECT display_value, return_value
FROM apex_appl_plugin_attr_values
WHERE attribute_id = (
  SELECT plugin_attribute_id 
  FROM apex_appl_plugin_attributes 
  WHERE plugin_static_id = 'FILE' AND static_id = 'storage_type'
);
exit;
