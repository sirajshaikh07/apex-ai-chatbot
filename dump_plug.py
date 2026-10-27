#!/usr/bin/env python3
import oracledb

oracledb.defaults.fetch_lobs = False
conn = oracledb.connect(user='AIDEMO', password='Apex_26ai_2026Free', dsn='20.0.1.130:1521/FREEPDB1')
cur = conn.cursor()
cur.execute('''SELECT region_source FROM apex_application_page_regions WHERE application_id = 101 AND page_id = 1 AND region_name = 'Chat Input Bar' ''')
row = cur.fetchone()
if row:
    with open('/home/ubuntu/docs/current_plug_source.html', 'w', encoding='utf-8') as f:
        f.write(row[0])
    print("Saved to current_plug_source.html")
cur.close()
conn.close()
