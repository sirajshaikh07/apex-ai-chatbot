#!/usr/bin/env bash
set -euo pipefail

source /home/ubuntu/project/values.env
source /home/ubuntu/.secrets.env

echo "--- SQL Diagnostics ---"
/usr/local/bin/sql -thin AIDEMO/"${AIDEMO_PWD}"@//${VM1_IP}:${DB_PORT}/${DB_SERVICE} @/home/ubuntu/docs/diagnose_ords.sql

echo ""
echo "--- HTTP Curl Diagnostic ---"
curl -s -i -X POST http://127.0.0.1:8080/ords/aidemo/api/chat \
  -H "Content-Type: application/json" \
  -d '{"question":"What is the guaranteed response time for a Severity 1 Critical Outage?"}' | head -n 30
