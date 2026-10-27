set serveroutput on linesize 220 pagesize 100
SELECT plugin_static_id, static_id, apexlang_name, attribute_scope
FROM apex_appl_plugin_attributes
WHERE plugin_static_id IN ('HIDDEN', 'TEXTAREA', 'TEXT_FIELD');
exit;
