#!/usr/bin/env bash
set -e

echo "======================================================="
echo "   BIOASQ RAG DATASET DOWNLOAD & ORACLE 26ai INGESTION"
echo "======================================================="

# 1. Activate hfenv if present
if [ -f "$HOME/hfenv/bin/activate" ]; then
    echo "[*] Activating virtual environment: ~/hfenv"
    source "$HOME/hfenv/bin/activate"
else
    echo "[*] Using system Python environment"
fi

# Ensure datasets is installed
python3 -c "import datasets" 2>/dev/null || pip install -U datasets --break-system-packages -q

WORK_DIR="/home/ubuntu/docs/rag_datasets"
mkdir -p "$WORK_DIR"
mkdir -p "$HOME/rag_datasets"

cd /home/ubuntu/docs

# Step 1: Download & Prepare QA Text File
echo ""
echo "[Step 1/2] Downloading enelpol/rag-mini-bioasq & generating QA text file..."
python3 /home/ubuntu/docs/download_and_prepare_bioasq.py

# Step 2: Ingest into Oracle 26ai Database
echo ""
echo "[Step 2/2] Ingesting BioASQ passages into Oracle 26ai with Vector Embeddings..."
python3 /home/ubuntu/docs/ingest_bioasq_to_db.py --limit 250

echo ""
echo "======================================================="
echo "   BIOASQ INGESTION COMPLETE & QA TEST FILE READY!"
echo "======================================================="
echo "• QA Test File (Text):   /home/ubuntu/docs/rag_datasets/bioasq_qa_testing.txt"
echo "• QA Test File (JSON):   /home/ubuntu/docs/rag_datasets/bioasq_qa_testing.json"
echo "• Total Chunks in DB:    Verified in Oracle 26ai doc_chunks"
echo ""
echo "--- PREVIEW OF TEST QA PAIRS (First 3 items) ---"
head -n 25 /home/ubuntu/docs/rag_datasets/bioasq_qa_testing.txt
