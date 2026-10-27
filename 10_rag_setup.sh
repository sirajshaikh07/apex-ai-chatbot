#!/usr/bin/env bash
set -euo pipefail

echo "=========================================================="
echo "  Deploying Enterprise Policy RAG Service & ORDS REST API"
echo "=========================================================="

source /home/ubuntu/project/values.env
source /home/ubuntu/.secrets.env

/usr/local/bin/sql -thin AIDEMO/"${AIDEMO_PWD}"@//${VM1_IP}:${DB_PORT}/${DB_SERVICE} @/home/ubuntu/docs/setup_ords_chat.sql

echo ""
echo "=== Testing REST Endpoint via Python Test Suite ==="
python3 /home/ubuntu/docs/test_enterprise_api.py
