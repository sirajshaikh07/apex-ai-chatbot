#!/usr/bin/env bash
set -e

echo "======================================================="
echo "   RESTARTING STREAMING RAG SERVICE & VERIFYING HEALTH"
echo "======================================================="

sudo systemctl restart streaming_rag.service
sleep 2

# Check systemd status
STATUS=$(sudo systemctl is-active streaming_rag.service || true)
echo "• Service status: $STATUS"

if [ "$STATUS" != "active" ]; then
    echo "[!] Error: streaming_rag.service failed to start. Journal logs:"
    sudo journalctl -u streaming_rag.service -n 25 --no-pager
    exit 1
fi

# Verify HTTP health check
echo "• Pinging http://127.0.0.1:5056/health..."
HEALTH=$(curl -s http://127.0.0.1:5056/health || echo "FAILED")
echo "• Health response: $HEALTH"

echo ""
echo "======================================================="
echo "   EXECUTING 30-QUESTION BENCHMARK ON RAG-12000"
echo "======================================================="
python3 /home/ubuntu/docs/run_rag12000_benchmark.py 30
