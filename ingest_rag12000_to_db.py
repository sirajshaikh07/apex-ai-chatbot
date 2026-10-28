#!/usr/bin/env python3
"""
Ingest neural-bridge/rag-dataset-12000 into Oracle Database 26ai
Applies Enterprise Standards:
1. Deduplicates contexts across records
2. Ingests into SOURCE_DOCS (status='ACTIVE')
3. Applies Universal Hierarchical Context Chunking into DOC_CHUNKS with ALL_MINILM_L12_V2 embeddings
4. Exports benchmark evaluation pairs for testing
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

def ingest_dataset(jsonl_path, max_docs=100, batch_size=20):
    if not os.path.exists(jsonl_path):
        print(f"[!] File not found: {jsonl_path}")
        return

    print(f"\n=======================================================")
    print(f"  INGESTING RAG-12000 INTO ORACLE 26ai")
    print(f"  File: {jsonl_path} | Target Limit: {max_docs} unique docs")
    print(f"=======================================================")

    conn = get_connection()
    cursor = conn.cursor()

    # 1. Read records and collect unique contexts + QA pairs
    unique_contexts = {} # hash -> (title, context)
    qa_pairs = []

    print("[*] Reading and deduplicating dataset records...")
    with open(jsonl_path, "r", encoding="utf-8") as f:
        for idx, line in enumerate(f, start=1):
            line = line.strip()
            if not line:
                continue
            rec = json.loads(line)
            
            ctx = rec.get("context") or rec.get("passage") or rec.get("text") or rec.get("document") or ""
            q = rec.get("question") or rec.get("query") or ""
            a = rec.get("answer") or rec.get("ground_truth") or ""

            if not ctx.strip():
                continue

            h = compute_hash(ctx.strip())
            if h not in unique_contexts:
                doc_title = f"RAG12K_Doc_{len(unique_contexts)+1:04d}"
                unique_contexts[h] = (doc_title, ctx.strip())

            qa_pairs.append({
                "question": q,
                "answer": a,
                "doc_title": unique_contexts[h][0],
                "doc_hash": h
            })

            if len(unique_contexts) >= max_docs:
                break

    print(f"[+] Loaded {len(unique_contexts)} unique documents and {len(qa_pairs)} QA pairs.")

    # 2. Ingest into SOURCE_DOCS and DOC_CHUNKS
    t0 = time.time()
    docs_inserted = 0
    chunks_inserted = 0

    for idx, (h, (title, content)) in enumerate(unique_contexts.items(), start=1):
        try:
            # Insert into SOURCE_DOCS
            cursor.execute("""
                MERGE INTO source_docs d
                USING (
                    SELECT :title AS title, 
                           :sref AS source_ref, 
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
                "sref": "neural-bridge/rag-dataset-12000",
                "content": content,
                "fhash": h,
                "fsize": len(content)
            })

            # Retrieve doc_id
            cursor.execute("SELECT doc_id FROM source_docs WHERE file_hash = :h", {"h": h})
            doc_id = cursor.fetchone()[0]

            # Clear any old chunks for this doc
            cursor.execute("DELETE FROM doc_chunks WHERE doc_id = :did", {"did": doc_id})

            # Ingest Chunks with Hierarchical Context Header Injection
            chunk_sql = """
            DECLARE
                l_chunk_no NUMBER := 0;
                l_full_chunk CLOB;
            BEGIN
                FOR c IN (
                    SELECT chunk_offset, chunk_text
                    FROM VECTOR_CHUNKS(:content BY characters MAX 1200 OVERLAP 100
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

            if idx % batch_size == 0 or idx == len(unique_contexts):
                conn.commit()
                elapsed = time.time() - t0
                print(f"  [Progress] Ingested {docs_inserted}/{len(unique_contexts)} docs ({chunks_inserted} chunks) in {elapsed:.1f}s...")

        except Exception as ex:
            print(f"  [!] Error ingesting doc {title}: {ex}")

    conn.commit()
    cursor.close()
    conn.close()

    total_time = time.time() - t0
    print(f"\n[SUCCESS] Completed Ingestion into Oracle 26ai!")
    print(f"  • Total Active Docs Ingested: {docs_inserted}")
    print(f"  • Total Vector Chunks Created: {chunks_inserted}")
    print(f"  • Total Ingestion Time:       {total_time:.2f}s (~{docs_inserted/max(1,total_time):.1f} docs/sec)")

    # 3. Save benchmark evaluation pairs
    data_dir = os.path.dirname(jsonl_path)
    out_eval = os.path.join(data_dir, "rag12000_eval_benchmark.json")
    with open(out_eval, "w", encoding="utf-8") as f:
        json.dump(qa_pairs[:max_docs * 2], f, indent=2, ensure_ascii=False)
    print(f"  • Benchmark QA pairs saved to: {out_eval}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Ingest RAG-12000 into Oracle 26ai")
    parser.add_argument("--limit", type=int, default=100, help="Number of unique documents to ingest (default: 100)")
    parser.add_argument("--split", choices=["train", "test"], default="test", help="Which split to ingest (default: test)")
    args = parser.parse_args()

    d_dir = "/home/ubuntu/docs/rag_datasets" if os.path.exists("/home/ubuntu/docs/rag_datasets") else os.path.expanduser("~/rag_datasets")
    file_name = f"rag12000_{args.split}.jsonl"
    file_path = os.path.join(d_dir, file_name)

    ingest_dataset(file_path, max_docs=args.limit)
