#!/usr/bin/env bash
set -e

echo "======================================================="
echo "   FINQA 20-QUESTION BENCHMARK EVALUATION"
echo "======================================================="

cd /home/ubuntu/docs

python3 /home/ubuntu/docs/run_finqa_benchmark.py 20
