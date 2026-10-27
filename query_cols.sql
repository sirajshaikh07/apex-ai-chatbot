SET LINESIZE 200 PAGESIZE 100;
SELECT column_name, data_type, data_length
FROM user_tab_cols
WHERE table_name = 'CHAT_HISTORY'
ORDER BY column_id;
EXIT;
