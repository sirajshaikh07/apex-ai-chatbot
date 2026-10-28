#!/usr/bin/env python3
"""
Download and Extract enelpol/rag-mini-bioasq
1. Downloads 'question-answer-passages' (train, test)
2. Downloads 'text-corpus'
3. Saves JSONL files to ~/rag_datasets and /home/ubuntu/docs/rag_datasets
4. Exports clean, human-readable QA text file: bioasq_qa_testing.txt
"""

import os
import sys
import json
from datasets import load_dataset

TARGET_DIRS = [
    os.path.expanduser("~/rag_datasets"),
    "/home/ubuntu/docs/rag_datasets"
]

for d in TARGET_DIRS:
    os.makedirs(d, exist_ok=True)

PRIMARY_DIR = "/home/ubuntu/docs/rag_datasets"

print("=======================================================")
print("  DOWNLOADING BIOASQ RAG DATASET (enelpol/rag-mini-bioasq)")
print("=======================================================\n")

# 1. Load Question-Answer-Passages
print("[1/4] Loading 'question-answer-passages'...")
qa = load_dataset('enelpol/rag-mini-bioasq', 'question-answer-passages')
print(f"  • QA Splits: {list(qa.keys())}")
for split in qa.keys():
    print(f"    - Split '{split}': {len(qa[split])} records")

# 2. Load Text-Corpus
print("\n[2/4] Loading 'text-corpus'...")
corpus = load_dataset('enelpol/rag-mini-bioasq', 'text-corpus')
print(f"  • Corpus Splits: {list(corpus.keys())}")
for split in corpus.keys():
    print(f"    - Split '{split}': {len(corpus[split])} passages")

# 3. Save JSONL files in both locations
print("\n[3/4] Exporting JSONL dataset files...")
for dest_dir in TARGET_DIRS:
    print(f"  Saving to {dest_dir}...")
    if 'train' in qa:
        qa['train'].to_json(os.path.join(dest_dir, 'bioasq_qa_train.jsonl'))
    if 'test' in qa:
        qa['test'].to_json(os.path.join(dest_dir, 'bioasq_qa_test.jsonl'))
    
    # Save corpus split (test or train or whichever is present)
    corpus_split = 'test' if 'test' in corpus else list(corpus.keys())[0]
    corpus[corpus_split].to_json(os.path.join(dest_dir, 'bioasq_corpus.jsonl'))

# 4. Generate Human-Readable QA Text File for Testing
print("\n[4/4] Generating dedicated QA testing text file...")
txt_path = os.path.join(PRIMARY_DIR, "bioasq_qa_testing.txt")
json_path = os.path.join(PRIMARY_DIR, "bioasq_qa_testing.json")

test_qa_data = qa['test'] if 'test' in qa else qa[list(qa.keys())[0]]

qa_export_list = []
with open(txt_path, "w", encoding="utf-8") as tf:
    tf.write("=" * 80 + "\n")
    tf.write("  BIOASQ BIOMEDICAL RAG DATASET - TEST QUESTIONS & GROUND TRUTH ANSWERS\n")
    tf.write("  Use these real biomedical questions to test the APEX AI Chatbot & RAG\n")
    tf.write(f"  Total Questions Available: {len(test_qa_data)}\n")
    tf.write("=" * 80 + "\n\n")

    for i, item in enumerate(test_qa_data, start=1):
        # Extract fields gracefully
        qid = item.get("id") or item.get("question_id") or f"BIOASQ_{i:04d}"
        q_text = item.get("question") or item.get("query") or ""
        
        # Answer might be a string or list
        raw_ans = item.get("answer") or item.get("ideal_answer") or item.get("exact_answer") or ""
        if isinstance(raw_ans, list):
            ans_text = " | ".join(str(a) for a in raw_ans if a)
        else:
            ans_text = str(raw_ans)
            
        passages = item.get("relevant_passage_ids") or item.get("passages") or item.get("relevant_passages") or []
        passage_ids = [str(p.get("id", "")) if isinstance(p, dict) else str(p) for p in passages]

        qa_export_list.append({
            "num": i,
            "id": qid,
            "question": q_text,
            "answer": ans_text,
            "relevant_passage_ids": passage_ids
        })

        tf.write(f"[Question {i}] (ID: {qid})\n")
        tf.write(f"  • Question: {q_text}\n")
        tf.write(f"  • Expected Answer: {ans_text}\n")
        if passage_ids:
            tf.write(f"  • Linked Passage IDs: {', '.join(passage_ids[:5])}\n")
        tf.write("-" * 80 + "\n\n")

with open(json_path, "w", encoding="utf-8") as jf:
    json.dump(qa_export_list, jf, indent=2, ensure_ascii=False)

print(f"[SUCCESS] BioASQ download & formatting complete!")
print(f"  • QA Text file for testing: {txt_path}")
print(f"  • QA JSON file:             {json_path}")
print(f"  • Total Test QA pairs:      {len(qa_export_list)}")
