#!/usr/bin/env bash
set -e

echo "======================================================="
echo "   FINQA FINANCIAL REASONING RAG PIPELINE"
echo "======================================================="

WORK_DIR="/home/ubuntu/docs/rag_datasets/finqa"
mkdir -p "$WORK_DIR"
mkdir -p "$HOME/rag_datasets/finqa"

cd /home/ubuntu/docs

# Step 1: Download & Extract FinQA + Generate QA Text File
echo ""
echo "[Step 1/2] Downloading & Extracting FinQA from GitHub/HuggingFace..."
python3 /home/ubuntu/docs/download_and_extract_finqa.py

# Step 2: Ingest into Oracle 26ai Database
echo ""
echo "[Step 2/2] Ingesting Financial Reports into Oracle 26ai with Vector Embeddings..."
python3 /home/ubuntu/docs/ingest_finqa_to_db.py --eval-limit 40 --doc-limit 100

echo ""
echo "======================================================="
echo "   FINQA INGESTION COMPLETE & QA TEST FILE READY!"
echo "======================================================="
echo "• QA Test File (Text):   /home/ubuntu/docs/rag_datasets/finqa/finqa_qa_testing.txt"
echo "• QA Test File (JSON):   /home/ubuntu/docs/rag_datasets/finqa/finqa_qa_testing.json"
echo "• Total Chunks in DB:    Verified in Oracle 26ai doc_chunks"
echo ""
echo "--- PREVIEW OF FINANCIAL QA QUESTIONS (First 3 items) ---"
head -n 25 /home/ubuntu/docs/rag_datasets/finqa/finqa_qa_testing.txt
