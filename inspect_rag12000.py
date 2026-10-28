#!/usr/bin/env python3
"""
Inspect Hugging Face Dataset: neural-bridge/rag-dataset-12000
Checks data schema, column types, sample records, and prepares for DB ingestion.
"""

import os
import sys
import json

DATA_DIR = "/home/ubuntu/docs/rag_datasets" if os.path.exists("/home/ubuntu/docs/rag_datasets") else os.path.expanduser("~/rag_datasets")
TRAIN_FILE = os.path.join(DATA_DIR, "rag12000_train.jsonl")
TEST_FILE = os.path.join(DATA_DIR, "rag12000_test.jsonl")

def inspect_file(file_path, split_name):
    print(f"\n=======================================================")
    print(f"  INSPECTING: {split_name} ({file_path})")
    print(f"=======================================================")
    
    if not os.path.exists(file_path):
        print(f"[!] File not found: {file_path}")
        return None

    count = 0
    keys = set()
    samples = []
    total_context_len = 0
    total_q_len = 0
    total_a_len = 0

    with open(file_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            count += 1
            record = json.loads(line)
            keys.update(record.keys())

            if len(samples) < 3:
                samples.append(record)

            # Compute character stats
            ctx = record.get("context") or record.get("passage") or record.get("text") or record.get("document") or ""
            q = record.get("question") or record.get("query") or ""
            a = record.get("answer") or record.get("ground_truth") or ""
            
            total_context_len += len(str(ctx))
            total_q_len += len(str(q))
            total_a_len += len(str(a))

    print(f"[+] Total Records:        {count:,}")
    print(f"[+] Detected Keys:         {list(keys)}")
    if count > 0:
        print(f"[+] Avg Context Length:    {round(total_context_len / count):,} chars")
        print(f"[+] Avg Question Length:   {round(total_q_len / count):,} chars")
        print(f"[+] Avg Answer Length:     {round(total_a_len / count):,} chars")

    print("\n--- SAMPLE RECORDS (First 2 entries) ---")
    for i, s in enumerate(samples[:2], 1):
        print(f"\n[Sample {i}]")
        for k, v in s.items():
            val_str = str(v)
            if len(val_str) > 250:
                val_str = val_str[:250] + " ... [TRUNCATED]"
            print(f"  • {k}: {val_str}")

    return {
        "split": split_name,
        "count": count,
        "keys": list(keys),
        "samples": samples
    }

def main():
    print("=== Neural-Bridge RAG Dataset (12,000) Data Checker ===")
    if not os.path.exists(DATA_DIR):
        print(f"[!] Directory {DATA_DIR} does not exist yet. Please download the dataset first.")
        sys.exit(1)

    t_info = inspect_file(TRAIN_FILE, "TRAIN SET")
    v_info = inspect_file(TEST_FILE, "TEST SET")
    print("\n[SUCCESS] Inspection complete.")

if __name__ == "__main__":
    main()
