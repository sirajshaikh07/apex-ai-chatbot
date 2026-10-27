#!/usr/bin/env python3
import oracledb

oracledb.defaults.fetch_lobs = False
conn = oracledb.connect(user='AIDEMO', password='Apex_26ai_2026Free', dsn='20.0.1.130:1521/FREEPDB1')
cur = conn.cursor()
cur.execute('''
    SELECT msg_id, user_prompt, ai_response, sources, response_time_ms, created_at
    FROM chat_history
    ORDER BY msg_id DESC
    FETCH FIRST 5 ROWS ONLY
''')

lines = []
for r in cur.fetchall():
    lines.append(f"=== MSG #{r[0]} | Time: {r[5]} | Latency: {r[4]}ms | Sources: {r[3]} ===")
    lines.append(f"User: {r[1]}")
    lines.append(f"AI Answer:\n{r[2]}")
    lines.append("-" * 70)

cur.close()
conn.close()

with open("/home/ubuntu/docs/live_chats_dump.txt", "w", encoding="utf-8") as f:
    f.write("\n".join(lines))
