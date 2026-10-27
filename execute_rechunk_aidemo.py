#!/usr/bin/env python3
"""
Rechunks Doc #161 as AIDEMO (100% owned by AIDEMO, zero SYSDBA needed).
Uses sentence-boundary chunking so words like 'medical certificates' are NEVER cut!
"""
import time
import oracledb

oracledb.defaults.fetch_lobs = False

LOG_FILE = "/home/ubuntu/docs/rechunk_aidemo_result.txt"

def main():
    t0 = time.time()
    out = []
    def log(msg):
        print(msg)
        out.append(msg)

    log("Connecting to Oracle 26ai DB as AIDEMO...")
    conn = oracledb.connect(
        user="AIDEMO",
        password="Apex_26ai_2026Free",
        dsn="20.0.1.130:1521/FREEPDB1"
    )
    cur = conn.cursor()

    try:
        log("Deleting old chopped chunks for Doc #161...")
        cur.execute("DELETE FROM doc_chunks WHERE doc_id = 161")
        log(f"Deleted {cur.rowcount} old chunks.")

        log("Re-chunking Doc #161 with SPLIT BY sentence...")
        sql = """
        INSERT INTO doc_chunks (doc_id, chunk_no, chunk_text, embedding)
        SELECT d.doc_id,
               ROW_NUMBER() OVER (PARTITION BY d.doc_id ORDER BY c.chunk_offset),
               '[Document: ' || d.title || '] ' || TRIM(c.chunk_text),
               VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING ('[Document: ' || d.title || '] ' || TRIM(c.chunk_text)) AS data)
        FROM   source_docs d,
               VECTOR_CHUNKS(d.content BY characters MAX 1200 OVERLAP 150
                             SPLIT BY sentence
                             LANGUAGE american NORMALIZE all) c
        WHERE  d.doc_id = 161
          AND  DBMS_LOB.GETLENGTH(TRIM(c.chunk_text)) > 40
        """
        cur.execute(sql)
        conn.commit()
        log(f"Inserted {cur.rowcount} clean sentence-aligned chunks!")

        log("Invalidating stale cache for probation/medical leave...")
        cur.execute("""
            DELETE FROM chat_history
            WHERE LOWER(user_prompt) LIKE '%medical%'
               OR LOWER(user_prompt) LIKE '%probation%'
               OR LOWER(user_prompt) LIKE '%certificate%'
        """)
        conn.commit()
        log(f"Deleted {cur.rowcount} stale cache rows.")

        # Test search for 'medical leave'
        q = "What is the policy for medical leave and certificates?"
        cur.execute("""
            SELECT c.chunk_no,
                   VECTOR_DISTANCE(c.embedding, VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING :q AS DATA), COSINE) as dist,
                   SUBSTR(c.chunk_text, 1, 200)
            FROM doc_chunks c
            WHERE c.doc_id = 161
            ORDER BY dist ASC
            FETCH FIRST 3 ROWS ONLY
        """, [q])
        log(f"\nTop 3 matches for '{q}':")
        for r in cur.fetchall():
            sim = (1.0 - r[1]) * 100
            log(f"  Chunk #{r[0]} | Distance: {r[1]:.4f} ({sim:.1f}%) | {r[2].replace(chr(10), ' ')[:100]}...")

        elapsed = time.time() - t0
        log(f"\nCompleted in {elapsed:.2f} seconds!")

    finally:
        cur.close()
        conn.close()

    with open(LOG_FILE, "w", encoding="utf-8") as f:
        f.write("\n".join(out))

if __name__ == "__main__":
    main()
