set serveroutput on linesize 220 pagesize 100
SELECT column_name, data_type
FROM all_tab_columns
WHERE table_name = 'APEX_APPLICATION_PAGE_ITEMS' AND column_name IN ('FILE_STORAGE', 'FILE_STORAGE_CODE', 'ITEM_SOURCE_TYPE', 'STORAGE_TYPE');

SELECT item_name, display_as, file_storage, file_storage_code, item_source_type
FROM apex_application_page_items
WHERE application_id = 101 AND item_name = 'P2_DOC_FILE';
exit;
