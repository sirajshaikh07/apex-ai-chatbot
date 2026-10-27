#!/usr/bin/env python3
import oracledb

oracledb.defaults.fetch_lobs = False
conn = oracledb.connect(user='AIDEMO', password='Apex_26ai_2026Free', dsn='20.0.1.130:1521/FREEPDB1')
cur = conn.cursor()
cur.execute('SELECT chunk_no, chunk_text FROM doc_chunks WHERE doc_id = 161 AND chunk_no BETWEEN 128 AND 134 ORDER BY chunk_no')

lines = []
for c_no, txt in cur.fetchall():
    lines.append(f"==================== CHUNK #{c_no} (Length: {len(txt)}) ====================")
    lines.append(txt)
    lines.append("\n")

cur.close()
conn.close()

with open("/home/ubuntu/docs/medical_chunks_dump.txt", "w", encoding="utf-8") as f:
    f.write("\n".join(lines))
print("Dumped to medical_chunks_dump.txt")
