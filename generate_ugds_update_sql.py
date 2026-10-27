#!/usr/bin/env python3
"""
Generates update_active_doc_ugds.sql to update source_docs with all_app_data_clean_ugds.txt
and re-chunk it with custom delimiters in Oracle 26ai.
"""

def main():
    with open('/home/ubuntu/docs/all_app_data_clean_ugds.txt', 'r', encoding='utf-8') as f:
        content = f.read()

    # Escape single quotes for SQL
    escaped = content.replace("'", "''")

    # Split into 2000-char slices to safely build CLOB in PL/SQL
    chunk_size = 2000
    slices = [escaped[i:i+chunk_size] for i in range(0, len(escaped), chunk_size)]

    sql_lines = [
        "SET DEFINE OFF;",
        "SET SERVEROUTPUT ON SIZE UNLIMITED;",
        "ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;",
        "",
        "DECLARE",
        "  l_doc_id NUMBER;",
        "  l_clob   CLOB;",
        "  l_cnt    NUMBER;",
        "BEGIN",
        "  SELECT MAX(doc_id) INTO l_doc_id FROM source_docs WHERE status = 'ACTIVE';",
        "  DBMS_OUTPUT.PUT_LINE('Target active doc_id: ' || l_doc_id);",
        "",
        "  DBMS_LOB.CREATETEMPORARY(l_clob, TRUE);"
    ]

    for s in slices:
        sql_lines.append(f"  DBMS_LOB.APPEND(l_clob, TO_CLOB('{s}'));")

    sql_lines.extend([
        "",
        "  -- Update active document content",
        "  UPDATE source_docs SET content = l_clob, status = 'ACTIVE' WHERE doc_id = l_doc_id;",
        "  DBMS_OUTPUT.PUT_LINE('Updated source_docs content length: ' || DBMS_LOB.GETLENGTH(l_clob));",
        "",
        "  -- Delete old chunks",
        "  DELETE FROM doc_chunks WHERE doc_id = l_doc_id;",
        "",
        "  -- Re-chunk using UGDS Custom Delimiters ('---', '# ', '## ', '### ')",
        "  INSERT INTO doc_chunks (doc_id, chunk_no, chunk_text, embedding, project_code, keywords)",
        "  SELECT d.doc_id, ",
        "         ROW_NUMBER() OVER (PARTITION BY d.doc_id ORDER BY c.chunk_offset),",
        "         '[Document: ' || d.title || '] ' || c.chunk_text,",
        "         VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING ('[Document: ' || d.title || '] ' || c.chunk_text) AS data),",
        "         NULL,",
        "         NULL",
        "  FROM   source_docs d,",
        "         VECTOR_CHUNKS(d.content BY characters MAX 1200 OVERLAP 100",
        "                       SPLIT CUSTOM ('---', '# ', '## ', '### ')",
        "                       LANGUAGE american NORMALIZE all) c",
        "  WHERE  d.doc_id = l_doc_id;",
        "",
        "  SELECT COUNT(*) INTO l_cnt FROM doc_chunks WHERE doc_id = l_doc_id;",
        "  DBMS_OUTPUT.PUT_LINE('New custom delimiter chunks created: ' || l_cnt);",
        "",
        "  UPDATE source_docs SET ingested_at = SYSTIMESTAMP WHERE doc_id = l_doc_id;",
        "  COMMIT;",
        "  DBMS_OUTPUT.PUT_LINE('SUCCESS: UGDS Ingestion Complete.');",
        "END;",
        "/",
        "EXIT;"
    ])

    with open('/home/ubuntu/docs/update_active_doc_ugds.sql', 'w', encoding='utf-8') as f:
        f.write("\n".join(sql_lines))

    print(f"[SUCCESS] Generated /home/ubuntu/docs/update_active_doc_ugds.sql ({len(slices)} CLOB slices)")

if __name__ == "__main__":
    main()
