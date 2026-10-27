DESC chat_history;
SELECT column_name, data_type, data_length FROM user_tab_cols WHERE table_name = 'CHAT_HISTORY' ORDER BY column_id;
EXIT;
