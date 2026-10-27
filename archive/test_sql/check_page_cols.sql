set pagesize 100 linesize 200 feedback off
SELECT column_name, data_type 
FROM all_tab_columns 
WHERE table_name = 'APEX_APPLICATION_PAGES' 
  AND (column_name LIKE '%CSS%' OR column_name LIKE '%JAVASCRIPT%');
exit;
