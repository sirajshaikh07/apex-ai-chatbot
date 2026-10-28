#!/usr/bin/env python3
"""
Download and Extract FinQA Dataset (Financial Numerical Reasoning RAG)
1. Downloads FinQA repo from GitHub or Hugging Face
2. Extracts dataset files (train.json, dev.json, test.json)
3. Formats financial tables and narrative into structured records
4. Generates dedicated human-readable QA testing text file: finqa_qa_testing.txt
"""

import os
import sys
import json
import urllib.request
import zipfile

TARGET_DIRS = [
    os.path.expanduser("~/rag_datasets/finqa"),
    "/home/ubuntu/docs/rag_datasets/finqa"
]

for d in TARGET_DIRS:
    os.makedirs(d, exist_ok=True)

PRIMARY_DIR = "/home/ubuntu/docs/rag_datasets/finqa"
ZIP_PATH = os.path.join(PRIMARY_DIR, "finqa.zip")

print("=======================================================")
print("  DOWNLOADING FINQA DATASET (Financial Reasoning RAG)")
print("=======================================================\n")

# 1. Download zip from GitHub repository
url = "https://github.com/czyssrs/FinQA/archive/refs/heads/main.zip"
print(f"[*] Downloading FinQA archive from: {url}...")
try:
    urllib.request.urlretrieve(url, ZIP_PATH)
    print(f"[+] Download complete: {os.path.getsize(ZIP_PATH)} bytes")
except Exception as e:
    print(f"[!] Error downloading from GitHub: {e}. Trying fallback...")
    sys.exit(1)

# 2. Extract dataset
print("[*] Extracting FinQA archive...")
with zipfile.ZipFile(ZIP_PATH, 'r') as zip_ref:
    zip_ref.extractall(PRIMARY_DIR)

# Also extract or copy to ~/rag_datasets/finqa
for d in TARGET_DIRS:
    if d != PRIMARY_DIR:
        with zipfile.ZipFile(ZIP_PATH, 'r') as zip_ref:
            zip_ref.extractall(d)

dataset_dir = os.path.join(PRIMARY_DIR, "FinQA-main", "dataset")
if not os.path.exists(dataset_dir):
    print(f"[!] Dataset directory not found at: {dataset_dir}")
    sys.exit(1)

print(f"[+] FinQA dataset extracted successfully to: {dataset_dir}")
for f in os.listdir(dataset_dir):
    f_path = os.path.join(dataset_dir, f)
    size_mb = os.path.getsize(f_path) / (1024 * 1024)
    print(f"  • {f} ({size_mb:.2f} MB)")

# 3. Parse test.json and dev.json to create human-readable QA testing files
test_file = os.path.join(dataset_dir, "test.json")
if not os.path.exists(test_file):
    test_file = os.path.join(dataset_dir, "dev.json")

print(f"\n[*] Parsing {os.path.basename(test_file)} to generate finqa_qa_testing.txt...")
with open(test_file, "r", encoding="utf-8") as f:
    test_data = json.load(f)

txt_out_path = os.path.join(PRIMARY_DIR, "finqa_qa_testing.txt")
json_out_path = os.path.join(PRIMARY_DIR, "finqa_qa_testing.json")

def format_table_markdown(table_rows):
    """Converts 2D table array into markdown format."""
    if not table_rows or not isinstance(table_rows, list):
        return ""
    lines = []
    header = table_rows[0]
    lines.append("| " + " | ".join(str(c).strip().replace("\n", " ") for c in header) + " |")
    lines.append("| " + " | ".join(["---"] * len(header)) + " |")
    for row in table_rows[1:]:
        # Pad row if needed
        row_cells = [str(c).strip().replace("\n", " ") for c in row]
        if len(row_cells) < len(header):
            row_cells.extend([""] * (len(header) - len(row_cells)))
        lines.append("| " + " | ".join(row_cells[:len(header)]) + " |")
    return "\n".join(lines)

formatted_qa_list = []
with open(txt_out_path, "w", encoding="utf-8") as tf:
    tf.write("=" * 85 + "\n")
    tf.write("  FINQA FINANCIAL REASONING BENCHMARK - TEST QUESTIONS & GROUND TRUTH\n")
    tf.write(f"  Source: S&P 500 Financial 10-K Reports | Total Records: {len(test_data)}\n")
    tf.write("=" * 85 + "\n\n")

    for i, item in enumerate(test_data, start=1):
        item_id = item.get("id", f"finqa_{i:04d}")
        qa_obj = item.get("qa", {})
        question = qa_obj.get("question", "").strip()
        exe_ans = qa_obj.get("exe_ans", "")
        program = qa_obj.get("program", "")
        gold_inds = qa_obj.get("gold_inds", {})

        pre_text = "\n".join(item.get("pre_text", []))
        table_raw = item.get("table", [])
        post_text = "\n".join(item.get("post_text", []))
        table_md = format_table_markdown(table_raw)

        full_report_text = f"--- Financial Report Background ---\n{pre_text}\n\n--- Financial Data Table ---\n{table_md}\n\n--- Financial Notes ---\n{post_text}"

        formatted_qa_list.append({
            "num": i,
            "id": item_id,
            "filename": item.get("filename", ""),
            "question": question,
            "answer": str(exe_ans),
            "calculation_steps": program,
            "report_content": full_report_text
        })

        tf.write(f"[Financial Question {i}] (ID: {item_id})\n")
        tf.write(f"  • Question:             {question}\n")
        tf.write(f"  • Numerical Answer:     {exe_ans}\n")
        tf.write(f"  • Calculation Formula:  {program}\n")
        tf.write(f"  • Source 10-K Filename: {item.get('filename', 'N/A')}\n")
        if table_raw:
            tf.write(f"  • Financial Table Preview:\n")
            # print up to 4 rows of table
            for row in table_raw[:4]:
                tf.write(f"      {' | '.join(str(c) for c in row)}\n")
        tf.write("-" * 85 + "\n\n")

with open(json_out_path, "w", encoding="utf-8") as jf:
    json.dump(formatted_qa_list, jf, indent=2, ensure_ascii=False)

print(f"\n[SUCCESS] FinQA processing complete!")
print(f"  • QA Text file for testing: {txt_out_path}")
print(f"  • QA JSON file:             {json_out_path}")
print(f"  • Total Test QA pairs:      {len(formatted_qa_list)}")
