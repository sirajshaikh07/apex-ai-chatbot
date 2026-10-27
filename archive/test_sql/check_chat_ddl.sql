SELECT column_name, data_default, identity_column FROM user_tab_cols WHERE table_name = 'CHAT_HISTORY' AND column_name = 'MSG_ID';
SELECT DBMS_METADATA.GET_DDL('TABLE', 'CHAT_HISTORY') FROM DUAL;
EXIT;
