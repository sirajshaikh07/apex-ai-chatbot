#!/usr/bin/env python3
import oracledb

oracledb.defaults.fetch_lobs = False
conn = oracledb.connect(user='AIDEMO', password='Apex_26ai_2026Free', dsn='20.0.1.130:1521/FREEPDB1')
cur = conn.cursor()
cur.execute('''
    SELECT chunk_no, DBMS_LOB.GETLENGTH(chunk_text), chunk_text 
    FROM doc_chunks 
    WHERE doc_id = 161 
      AND (UPPER(chunk_text) LIKE '%SICK%' OR UPPER(chunk_text) LIKE '%MEDICAL%' OR UPPER(chunk_text) LIKE '%CERTIFICATE%')
    ORDER BY chunk_no
''')
rows = cur.fetchall()

lines = [f"Total matching chunks: {len(rows)}"]
for c_no, l, txt in rows:
    lines.append(f"\n--- Chunk #{c_no} (len {l}) ---")
    lines.append(txt[:400].replace('\n', ' '))

cur.close()
conn.close()

with open("/home/ubuntu/docs/sick_leave_search_results.txt", "w", encoding="utf-8") as f:
    f.write("\n".join(lines))
print("Saved to sick_leave_search_results.txt")
