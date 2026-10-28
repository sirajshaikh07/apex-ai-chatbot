#!/usr/bin/env bash
set -e

# ==============================================================================
# Master Automated Pipeline for neural-bridge/rag-dataset-12000
# 1. Downloads dataset from Hugging Face
# 2. Inspects schema, record counts, character lengths, and samples ("Check first")
# 3. Ingests deduplicated documents into Oracle 26ai with vector embeddings
# 4. Executes live automated RAG benchmark evaluation
# ==============================================================================

echo "======================================================="
echo "   ENTERPRISE RAG DATASET BENCHMARK PIPELINE"
echo "======================================================="

WORK_DIR="/home/ubuntu/docs/rag_datasets"
mkdir -p "$WORK_DIR"
cd /home/ubuntu/docs

# Step 1: Install / Ensure datasets library
echo "[1/4] Ensuring Hugging Face 'datasets' library is installed..."
python3 -m pip install -U datasets --break-system-packages -q 2>/dev/null || pip install -U datasets --break-system-packages -q

# Step 2: Download Dataset from Hugging Face
if [ ! -f "$WORK_DIR/rag12000_test.jsonl" ]; then
    echo "[2/4] Downloading 'neural-bridge/rag-dataset-12000' from Hugging Face..."
    python3 -c "
from datasets import load_dataset
print('  Connecting to Hugging Face Hub...')
ds = load_dataset('neural-bridge/rag-dataset-12000')
print('  Saving train and test splits to $WORK_DIR...')
ds['train'].to_json('$WORK_DIR/rag12000_train.jsonl')
ds['test'].to_json('$WORK_DIR/rag12000_test.jsonl')
print('  Download complete!')
"
else
    echo "[2/4] Dataset files already present in $WORK_DIR. Skipping re-download."
fi

# Step 3: Check Data First (Schema, Stats, Sample Records)
echo ""
echo "[3/4] Checking Data First (Schema & Samples)..."
python3 /home/ubuntu/docs/inspect_rag12000.py

# Step 4: Ingest into Oracle 26ai Database
echo ""
echo "[4/4] Ingesting documents into Oracle 26ai DB with Vector Embeddings..."
python3 /home/ubuntu/docs/ingest_rag12000_to_db.py --limit 100 --split test

echo ""
echo "======================================================="
echo "   RESTARTING STREAMING SERVICE & RUNNING BENCHMARK"
echo "======================================================="
sudo systemctl restart streaming_rag.service
sleep 2
python3 /home/ubuntu/docs/run_rag12000_benchmark.py 30

echo ""
echo "🎉 ALL DONE! Your Oracle 26ai database is now populated with real Hugging Face RAG benchmark data."
