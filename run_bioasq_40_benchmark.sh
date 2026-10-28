#!/usr/bin/env bash
set -e

echo "======================================================="
echo "   BIOASQ 40-QUESTION BENCHMARK & INGESTION PIPELINE"
echo "======================================================="

cd /home/ubuntu/docs

# Step 1: Ensure prioritized passages are ingested into Oracle 26ai DB
echo ""
echo "[1/2] Ingesting priority passages for the 40 test questions into Oracle 26ai..."
python3 /home/ubuntu/docs/ingest_bioasq_to_db.py --eval-limit 40 --doc-limit 250

# Step 2: Run 40 questions automated benchmark
echo ""
echo "[2/2] Running automated benchmark evaluation on 40 BioASQ questions..."
python3 /home/ubuntu/docs/run_bioasq_benchmark.py 40

echo ""
echo "🎉 40-Question BioASQ Benchmark Finished Successfully!"
