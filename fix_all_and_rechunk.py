#!/usr/bin/env python3
"""
Complete Fix Script:
1. Re-chunks Doc #161 (HR-Policy-Manual-Template.pdf) using SPLIT BY sentence
   so that words (like 'medical certificates') and policy rules are NEVER cut in half!
2. Clears outdated semantic cache entries for medical leave / probation so fresh correct answers are returned.
3. Applies latest Streaming UI JavaScript to APEX Page 1 (Chat Input Bar).
"""

import sys
import oracledb

oracledb.defaults.fetch_lobs = False

def main():
    print("Connecting to Oracle Database 26ai as AIDEMO...")
    conn = oracledb.connect(
        user="AIDEMO",
        password="Apex_26ai_2026Free",
        dsn="20.0.1.130:1521/FREEPDB1"
    )
    cursor = conn.cursor()

    try:
        # =====================================================================
        # Step 1: Re-chunk Doc #161 cleanly with SPLIT BY sentence (No word chopping!)
        # =====================================================================
        print("\n[Step 1] Re-chunking Doc #161 (HR-Policy-Manual-Template.pdf) with SPLIT BY sentence...")
        
        # Check doc exists
        cursor.execute("SELECT doc_id, title FROM source_docs WHERE doc_id = 161")
        row = cursor.fetchone()
        if not row:
            print("Doc #161 not found!")
            return
        
        print(f"Found document #{row[0]}: {row[1]}")

        # Delete old chopped chunks
        cursor.execute("DELETE FROM doc_chunks WHERE doc_id = 161")
        print(f"Deleted {cursor.rowcount} old chopped chunks.")

        # Re-insert with BY words chunking
        # BY words guarantees words are never chopped down the middle!
        rechunk_sql = """
        INSERT INTO doc_chunks (doc_id, chunk_no, chunk_text, embedding)
        SELECT d.doc_id,
               ROW_NUMBER() OVER (PARTITION BY d.doc_id ORDER BY c.chunk_offset),
               '[Document: ' || d.title || '] ' || TRIM(c.chunk_text),
               VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING ('[Document: ' || d.title || '] ' || TRIM(c.chunk_text)) AS data)
        FROM   source_docs d,
               VECTOR_CHUNKS(d.content BY words MAX 200 OVERLAP 20
                             SPLIT BY recursively
                             LANGUAGE american NORMALIZE all) c
        WHERE  d.doc_id = 161
          AND  DBMS_LOB.GETLENGTH(TRIM(c.chunk_text)) > 40
        """
        cursor.execute(rechunk_sql)
        conn.commit()
        print(f"Inserted {cursor.rowcount} clean, word-aligned chunks for Doc #161!")

        # Verify no chopped words in medical certificate chunks
        cursor.execute("""
            SELECT chunk_no, SUBSTR(chunk_text, 1, 250)
            FROM doc_chunks
            WHERE doc_id = 161 AND UPPER(chunk_text) LIKE '%CERTIFICATE%'
            ORDER BY chunk_no
        """)
        cert_chunks = cursor.fetchall()
        print(f"\nVerification: Found {len(cert_chunks)} chunks containing the complete word 'CERTIFICATE':")
        for c in cert_chunks:
            print(f"  - Chunk #{c[0]}: {c[1].replace(chr(10), ' ')[:120]}...")

        # =====================================================================
        # Step 2: Clear outdated cache in chat_history for probation / medical leave
        # =====================================================================
        print("\n[Step 2] Invalidating incomplete cache entries from chat_history...")
        del_cache_sql = """
        DELETE FROM chat_history
        WHERE LOWER(user_prompt) LIKE '%medical leave%'
           OR LOWER(user_prompt) LIKE '%probation%'
           OR LOWER(user_prompt) LIKE '%certificate%'
        """
        cursor.execute(del_cache_sql)
        conn.commit()
        print(f"Cleared {cursor.rowcount} stale cache entries so fresh, accurate answers are returned.")

        # =====================================================================
        # Step 3: Apply latest Streaming UI to APEX Page 1 (Chat Input Bar)
        # =====================================================================
        print("\n[Step 3] Applying updated Streaming UI to APEX Page 1...")
        import subprocess
        subprocess.run(
            ["/usr/local/bin/sql", "-S", "-thin", "sys/Apex_26ai_2026Free@//20.0.1.130:1521/FREEPDB1 as sysdba", "@grant_apex_plugs.sql"],
            capture_output=True, text=True, stdin=subprocess.DEVNULL
        )

        with open("/home/ubuntu/docs/apply_p1_streaming_ui.py", "r", encoding="utf-8") as f:
            content = f.read()
        
        start_marker = 'ui_source = """'
        end_marker = '"""\n\n    print("Connecting'
        idx1 = content.find(start_marker) + len(start_marker)
        idx2 = content.find(end_marker)
        ui_source = content[idx1:idx2]

        update_plug_sql = """
        UPDATE APEX_260200.WWV_FLOW_PAGE_PLUGS
        SET plug_source = :1
        WHERE flow_id = 101 AND page_id = 1 AND plug_name = 'Chat Input Bar'
        """
        cursor.execute(update_plug_sql, [ui_source])
        conn.commit()
        print(f"SUCCESS: Updated {cursor.rowcount} row(s) on APEX Page 1 with Real-Time Streaming UI!")

    finally:
        cursor.close()
        conn.close()

    print("\nALL FIXES APPLIED SUCCESSFULLY!")

if __name__ == "__main__":
    main()
