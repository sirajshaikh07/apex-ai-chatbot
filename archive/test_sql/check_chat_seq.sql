SELECT trigger_name, status FROM user_triggers WHERE table_name = 'CHAT_HISTORY';
SELECT sequence_name FROM user_sequences WHERE sequence_name LIKE '%CHAT%';
EXIT;
