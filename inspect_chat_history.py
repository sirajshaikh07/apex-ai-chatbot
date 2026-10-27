import oracledb

conn = oracledb.connect(user='AIDEMO', password='Apex_26ai_2026Free', dsn='20.0.1.130:1521/FREEPDB1')
cur = conn.cursor()
cur.execute("SELECT column_name, data_type, data_length FROM user_tab_cols WHERE table_name = 'CHAT_HISTORY' ORDER BY column_id")
for col in cur:
    print(col)
cur.close()
conn.close()
