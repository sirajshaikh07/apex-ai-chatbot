set pagesize 100 linesize 200 feedback off
SELECT item_name, display_as, attribute_01, protection_level 
FROM apex_application_page_items 
WHERE application_id = 101 AND item_name = 'P1_QUESTION';
exit;
