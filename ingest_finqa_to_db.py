#!/usr/bin/env python3
"""
Ingest FinQA (Financial 10-K Reports & Tables) into Oracle Database 26ai
- Preserves tabular structures via Markdown Table formatting
- Ingests into SOURCE_DOCS (status='ACTIVE', source_ref='ibm-research/finqa')
- Generates DOC_CHUNKS with ALL_MINILM_L12_V2 vector embeddings
- Exports benchmark evaluation pairs
"""

import os
import sys
import json
import hashlib
import time
import argparse
import oracledb

DB_CONFIG = {
    "user": "AIDEMO",
    "password": "Apex_26ai_2026Free",
    "dsn": "20.0.1.130:1521/FREEPDB1"
}

def get_connection():
    return oracledb.connect(**DB_CONFIG)

def compute_hash(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()

def format_table_markdown(table_rows):
    if not table_rows or not isinstance(table_rows, list):
        return ""
    lines = []
    header = table_rows[0]
    lines.append("| " + " | ".join(str(c).strip().replace("\n", " ") for c in header) + " |")
    lines.append("| " + " | ".join(["---"] * len(header)) + " |")
    for row in table_rows[1:]:
        row_cells = [str(c).strip().replace("\n", " ") for c in row]
        if len(row_cells) < len(header):
            row_cells.extend([""] * (len(header) - len(row_cells)))
        lines.append("| " + " | ".join(row_cells[:len(header)]) + " |")
    return "\n".join(lines)

def ingest_finqa(json_path, max_eval=40, max_docs=100, batch_size=20):
    print(f"\n=======================================================")
    print(f"  INGESTING FINQA FINANCIAL REPORTS INTO ORACLE 26ai")
    print(f"  Source File: {json_path}")
    print(f"  Benchmark Target: First {max_eval} Financial Questions")
    print(f"  Report Limit: {max_docs} reports")
    print(f"=======================================================")

    if not os.path.exists(json_path):
        print(f"[!] File not found: {json_path}")
        return

    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    # 1. Deduplicate reports and associate QA pairs
    unique_reports = {} # doc_id -> (title, full_content, filename)
    qa_items = []

    for i, item in enumerate(data, start=1):
        item_id = item.get("id", f"finqa_{i:04d}")
        qa_obj = item.get("qa", {})
        question = qa_obj.get("question", "").strip()
        exe_ans = str(qa_obj.get("exe_ans", ""))
        program = qa_obj.get("program", "")
        filename = item.get("filename", "")

        pre_text = "\n".join(item.get("pre_text", []))
        table_md = format_table_markdown(item.get("table", []))
        post_text = "\n".join(item.get("post_text", []))

        full_content = (
            f"[Financial Report Filing: {filename}]\n"
            f"--- Section Narrative ---\n{pre_text}\n\n"
            f"--- Financial Statement / Table ---\n{table_md}\n\n"
            f"--- Footnotes & Explanations ---\n{post_text}"
        )

        doc_title = f"FinQA_Report_{item_id}"
        if item_id not in unique_reports:
            unique_reports[item_id] = (doc_title, full_content, filename)

        qa_items.append({
            "num": i,
            "id": item_id,
            "question": question,
            "answer": exe_ans,
            "calculation_formula": program,
            "filename": filename,
            "doc_title": doc_title,
            "expected_docs": [doc_title]
        })

    # Save benchmark evaluation file
    out_dir = os.path.dirname(json_path)
    eval_benchmark_path = os.path.join(out_dir, "finqa_eval_benchmark.json")
    with open(eval_benchmark_path, "w", encoding="utf-8") as bf:
        json.dump(qa_items[:max_eval], bf, indent=2, ensure_ascii=False)
    print(f"[+] Saved {min(len(qa_items), max_eval)} benchmark evaluation pairs to: {eval_benchmark_path}")

    # Select docs to ingest (prioritize those in benchmark)
    priority_ids = [q["id"] for q in qa_items[:max_eval]]
    selected_doc_ids = priority_ids + [did for did in unique_reports.keys() if did not in priority_ids]
    selected_doc_ids = selected_doc_ids[:max_docs]

    print(f"[+] Ingesting {len(selected_doc_ids)} reports into Oracle 26ai DB...")

    conn = get_connection()
    cursor = conn.cursor()

    t0 = time.time()
    docs_inserted = 0
    chunks_inserted = 0

    for idx, did in enumerate(selected_doc_ids, start=1):
        title, content, filename = unique_reports[did]
        fhash = compute_hash(f"{title}_{content}")

        try:
            cursor.execute("""
                MERGE INTO source_docs d
                USING (
                    SELECT :title AS title, 
                           'ibm-research/finqa' AS source_ref, 
                           :content AS content, 
                           :fhash AS file_hash, 
                           :fsize AS file_size, 
                           'ACTIVE' AS status, 
                           1 AS version_no 
                    FROM dual
                ) s
                ON (d.file_hash = s.file_hash)
                WHEN MATCHED THEN
                    UPDATE SET status = 'ACTIVE'
                WHEN NOT MATCHED THEN
                    INSERT (title, source_ref, content, file_hash, file_size, status, version_no, ingested_at)
                    VALUES (s.title, s.source_ref, s.content, s.file_hash, s.file_size, s.status, s.version_no, SYSTIMESTAMP)
            """, {
                "title": title,
                "content": content,
                "fhash": fhash,
                "fsize": len(content)
            })

            cursor.execute("SELECT doc_id FROM source_docs WHERE file_hash = :h", {"h": fhash})
            doc_id = cursor.fetchone()[0]

            cursor.execute("DELETE FROM doc_chunks WHERE doc_id = :did", {"did": doc_id})

            chunk_sql = """
            DECLARE
                l_chunk_no NUMBER := 0;
                l_full_chunk CLOB;
            BEGIN
                FOR c IN (
                    SELECT chunk_offset, chunk_text
                    FROM VECTOR_CHUNKS(:content BY characters MAX 1500 OVERLAP 150
                                       SPLIT CUSTOM ('---', '# ', '## ', '### ')
                                       LANGUAGE american NORMALIZE all)
                    ORDER BY chunk_offset ASC
                ) LOOP
                    l_chunk_no := l_chunk_no + 1;
                    l_full_chunk := '[Document: ' || :title || '] ' || c.chunk_text;
                    
                    INSERT INTO doc_chunks (doc_id, chunk_no, chunk_text, embedding)
                    VALUES (
                        :did,
                        l_chunk_no,
                        l_full_chunk,
                        VECTOR_EMBEDDING(ALL_MINILM_L12_V2 USING l_full_chunk AS DATA)
                    );
                END LOOP;
            END;
            """
            cursor.execute(chunk_sql, {
                "content": content,
                "title": title,
                "did": doc_id
            })

            cursor.execute("SELECT count(*) FROM doc_chunks WHERE doc_id = :did", {"did": doc_id})
            c_cnt = cursor.fetchone()[0]
            chunks_inserted += c_cnt
            docs_inserted += 1

            if idx % batch_size == 0 or idx == len(selected_doc_ids):
                conn.commit()
                elapsed = time.time() - t0
                print(f"  [Progress] Ingested {docs_inserted}/{len(selected_doc_ids)} reports ({chunks_inserted} vector chunks) in {elapsed:.1f}s...")

        except Exception as ex:
            print(f"  [!] Error ingesting {title}: {ex}")

    conn.commit()
    cursor.close()
    conn.close()

    total_time = time.time() - t0
    print(f"\n[SUCCESS] Completed FinQA Ingestion into Oracle 26ai!")
    print(f"  • Total Active Financial Reports Ingested: {docs_inserted}")
    print(f"  • Total Vector Chunks Created:             {chunks_inserted}")
    print(f"  • Total Ingestion Time:                   {total_time:.2f}s (~{docs_inserted/max(1,total_time):.1f} docs/sec)")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Ingest FinQA into Oracle 26ai")
    parser.add_argument("--eval-limit", type=int, default=40, help="Number of benchmark QA items (default: 40)")
    parser.add_argument("--doc-limit", type=int, default=100, help="Max reports to ingest (default: 100)")
    args = parser.parse_args()

    j_path = "/home/ubuntu/docs/rag_datasets/finqa/FinQA-main/dataset/test.json"
    if not os.path.exists(j_path):
        j_path = os.path.expanduser("~/rag_datasets/finqa/FinQA-main/dataset/test.json")

    ingest_finqa(j_path, max_eval=args.eval_limit, max_docs=args.doc_limit)
