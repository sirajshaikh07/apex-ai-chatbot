set pagesize 100 linesize 200 feedback off long 10000
SELECT item_name, display_as, item_protection_level, attribute_01, attributes 
FROM apex_application_page_items 
WHERE application_id = 101 AND item_name = 'P1_QUESTION';
exit;
