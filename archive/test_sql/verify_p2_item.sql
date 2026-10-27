set serveroutput on linesize 220 pagesize 100 long 50000
SELECT item_name, display_as, attributes
FROM apex_application_page_items
WHERE application_id = 101 AND item_name = 'P2_DOC_FILE';
exit;
