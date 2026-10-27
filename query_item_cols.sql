set pagesize 100 linesize 200 feedback off
SELECT column_name FROM all_tab_columns WHERE table_name = 'APEX_APPLICATION_PAGE_ITEMS' AND (column_name LIKE '%PROT%' OR column_name LIKE '%ATTR%');
exit;
