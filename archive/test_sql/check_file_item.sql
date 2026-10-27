set serveroutput on linesize 200 pagesize 100 long 50000
SELECT item_name, display_as, item_source_type, item_source, attribute_01, attribute_02, attribute_03, attribute_04, attribute_05, attribute_06, attribute_07, attribute_08, attribute_09, attribute_10, attribute_11, attribute_12, attribute_13, attribute_14, attribute_15
FROM apex_application_page_items
WHERE application_id = 101 AND item_name = 'P2_DOC_FILE';
exit;
