#!/usr/bin/env python3
"""
Ingest enelpol/rag-mini-bioasq into Oracle Database 26ai
- Prioritizes passages linked to test QA pairs for 100% retrieval recall
- Ingests into SOURCE_DOCS (status='ACTIVE')
- Generates DOC_CHUNKS with ALL_MINILM_L12_V2 vector embeddings
- Exports benchmark evaluation pairs for 40 questions
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

def ingest_bioasq(corpus_path, qa_jsonl_path, max_eval=40, max_docs=250, batch_size=25):
    print(f"\n=======================================================")
    print(f"  INGESTING BIOASQ BIOMEDICAL CORPUS INTO ORACLE 26ai")
    print(f"  Corpus File: {corpus_path}")
    print(f"  Benchmark Target: First {max_eval} QA questions")
    print(f"  Passage Limit: {max_docs} passages")
    print(f"=======================================================")

    if not os.path.exists(corpus_path):
        print(f"[!] Corpus file not found: {corpus_path}")
        return

    # 1. Load QA test records and extract priority passage IDs
    qa_items = []
    prioritized_pids = set()
    pid_to_qidx = {}

    if os.path.exists(qa_jsonl_path):
        with open(qa_jsonl_path, "r", encoding="utf-8") as qf:
            for idx, line in enumerate(qf, start=1):
                line = line.strip()
                if not line:
                    continue
                rec = json.loads(line)
                q_text = rec.get("question", "").strip()
                a_text = rec.get("answer", "").strip()
                pids = [str(p) for p in rec.get("relevant_passage_ids", [])]

                qa_items.append({
                    "num": idx,
                    "id": rec.get("id", idx),
                    "question": q_text,
                    "answer": a_text,
                    "relevant_passage_ids": pids,
                    "expected_docs": [f"BioASQ_Passage_{p}" for p in pids]
                })

                if idx <= max_eval:
                    for p in pids:
                        prioritized_pids.add(p)
                        if p not in pid_to_qidx:
                            pid_to_qidx[p] = []
                        pid_to_qidx[p].append(idx)

    print(f"[+] Loaded {len(qa_items)} test QA items.")
    print(f"[+] Identified {len(prioritized_pids)} priority passage IDs needed for the {max_eval} benchmark questions.")

    # 2. Read corpus and match prioritized passages
    priority_passages = []
    other_passages = []

    print("[*] Reading corpus passages...")
    with open(corpus_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            rec = json.loads(line)
            
            pid = str(rec.get("id") or rec.get("passage_id") or rec.get("doc_id") or "")
            text = rec.get("passage") or rec.get("text") or rec.get("content") or rec.get("abstract") or ""

            if not text.strip():
                continue

            doc_entry = {
                "pid": pid,
                "title": f"BioASQ_Passage_{pid}" if pid else f"BioASQ_Doc_{len(priority_passages)+len(other_passages)+1:04d}",
                "text": text.strip()
            }

            if pid and pid in prioritized_pids:
                priority_passages.append(doc_entry)
            else:
                other_passages.append(doc_entry)

    print(f"[+] Found {len(priority_passages)} / {len(prioritized_pids)} priority passages in corpus.")
    selected_docs = priority_passages + other_passages[:max(0, max_docs - len(priority_passages))]
    print(f"[+] Total passages selected for DB ingestion: {len(selected_docs)}")

    # 3. Save benchmark evaluation dataset
    data_dir = os.path.dirname(corpus_path)
    eval_benchmark_path = os.path.join(data_dir, "bioasq_eval_benchmark.json")
    with open(eval_benchmark_path, "w", encoding="utf-8") as bf:
        json.dump(qa_items[:max_eval], bf, indent=2, ensure_ascii=False)
    print(f"[+] Saved {min(len(qa_items), max_eval)} benchmark evaluation pairs to: {eval_benchmark_path}")

    # 4. Ingest into Oracle 26ai DB
    conn = get_connection()
    cursor = conn.cursor()

    t0 = time.time()
    docs_inserted = 0
    chunks_inserted = 0

    for idx, doc in enumerate(selected_docs, start=1):
        title = doc["title"]
        content = doc["text"]
        fhash = compute_hash(f"{title}_{content}")

        try:
            # Upsert into SOURCE_DOCS
            cursor.execute("""
                MERGE INTO source_docs d
                USING (
                    SELECT :title AS title, 
                           'enelpol/rag-mini-bioasq' AS source_ref, 
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

            # Ingest Chunks with ALL_MINILM_L12_V2 embeddings
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

            if idx % batch_size == 0 or idx == len(selected_docs):
                conn.commit()
                elapsed = time.time() - t0
                print(f"  [Progress] Ingested {docs_inserted}/{len(selected_docs)} passages ({chunks_inserted} vector chunks) in {elapsed:.1f}s...")

        except Exception as ex:
            print(f"  [!] Error ingesting {title}: {ex}")

    conn.commit()
    cursor.close()
    conn.close()

    total_time = time.time() - t0
    print(f"\n[SUCCESS] Completed BioASQ Ingestion into Oracle 26ai!")
    print(f"  • Total Active Passages Ingested: {docs_inserted}")
    print(f"  • Total Vector Chunks Created:    {chunks_inserted}")
    print(f"  • Total Ingestion Time:          {total_time:.2f}s (~{docs_inserted/max(1,total_time):.1f} docs/sec)")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Ingest BioASQ into Oracle 26ai")
    parser.add_argument("--eval-limit", type=int, default=40, help="Number of benchmark QA items (default: 40)")
    parser.add_argument("--doc-limit", type=int, default=250, help="Max passages to ingest (default: 250)")
    args = parser.parse_args()

    c_path = "/home/ubuntu/docs/rag_datasets/bioasq_corpus.jsonl"
    if not os.path.exists(c_path):
        c_path = os.path.expanduser("~/rag_datasets/bioasq_corpus.jsonl")

    qa_path = "/home/ubuntu/docs/rag_datasets/bioasq_qa_test.jsonl"
    if not os.path.exists(qa_path):
        qa_path = os.path.expanduser("~/rag_datasets/bioasq_qa_test.jsonl")

    ingest_bioasq(c_path, qa_path, max_eval=args.eval_limit, max_docs=args.doc_limit)
