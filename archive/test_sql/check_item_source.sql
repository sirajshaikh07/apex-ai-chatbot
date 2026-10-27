set serveroutput on linesize 220 pagesize 100
SELECT column_name, data_type
FROM all_tab_columns
WHERE table_name = 'APEX_APPLICATION_PAGE_ITEMS' AND column_name LIKE '%SOURCE%' OR column_name LIKE '%STORAGE%';
exit;
