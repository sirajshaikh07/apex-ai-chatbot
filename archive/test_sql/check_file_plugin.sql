set serveroutput on linesize 200 pagesize 100
SELECT attribute_scope, attribute_sequence, attribute_identifier, prompt, default_value, is_required
FROM all_tab_columns
WHERE table_name LIKE '%PLUGIN%ATTR%'
FETCH FIRST 5 ROWS ONLY;

SELECT view_name FROM all_views WHERE view_name LIKE '%PLUGIN%';
exit;
