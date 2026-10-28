#!/usr/bin/env python3
"""
Applies Feature 4 (Hybrid Search Sandbox) to Page 2 (Admin Center)
Updates APEX_260200.WWV_FLOW_PAGE_PLUGS for 'Active Knowledge Base'
"""
import oracledb

def main():
    conn = oracledb.connect(user="AIDEMO", password="Apex_26ai_2026Free", dsn="20.0.1.130:1521/FREEPDB1")
    cur = conn.cursor()

    # Read the PL/SQL source from update_p2_sandbox.sql
    with open("/home/ubuntu/docs/update_p2_sandbox.sql", "r", encoding="utf-8") as f:
        sql_content = f.read()

    # Extract the block inside l_source := q'[ ... ]';
    start_tag = "l_source := q'["
    end_tag = "]';"
    idx1 = sql_content.find(start_tag)
    idx2 = sql_content.find(end_tag, idx1)

    if idx1 != -1 and idx2 != -1:
        plsql_body = sql_content[idx1 + len(start_tag):idx2]
        print(f"Extracted PL/SQL dynamic content source ({len(plsql_body)} chars).")

        cur.execute("""
            UPDATE APEX_260200.WWV_FLOW_PAGE_PLUGS
            SET plug_source = :1
            WHERE flow_id = 101 AND page_id = 2 AND plug_name = 'Active Knowledge Base'
        """, [plsql_body])

        conn.commit()
        print(f"Rows updated: {cur.rowcount}")
        if cur.rowcount > 0:
            print("SUCCESS: Hybrid Search Sandbox (Feature 4) applied to Page 2!")
        else:
            print("WARNING: No rows matched flow_id=101, page_id=2, plug_name='Active Knowledge Base'")
    else:
        print("ERROR: Could not parse l_source delimiters in update_p2_sandbox.sql")

    cur.close()
    conn.close()

if __name__ == "__main__":
    main()
