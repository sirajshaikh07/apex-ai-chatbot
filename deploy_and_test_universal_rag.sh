#!/usr/bin/env bash
set -e

echo "======================================================================"
echo "DEPLOYING UNIVERSAL ENTERPRISE RAG ARCHITECTURE & RUNNING 5 EXAMPLES"
echo "======================================================================"

echo ""
echo "[1/4] Applying Universal RAG Code Fixes to enterprise_rag_pkg.sql..."
python3 apply_universal_rag_fixes.py

echo ""
echo "[2/4] Syncing Enterprise Projects to Active Document in Database..."
python3 run_sql.py fix_schema_doc_sync.sql

echo ""
echo "[3/4] Compiling ENTERPRISE_RAG_PKG & POLICY_RAG_PKG..."
python3 run_sql.py enterprise_rag_pkg.sql

echo ""
echo "[4/4] Deploying Upgraded ORDS REST API Module with Session Context..."
python3 run_sql.py setup_ords_chat.sql

echo ""
echo "======================================================================"
echo "RUNNING COMPREHENSIVE 5-EXAMPLE VERIFICATION SUITE"
echo "======================================================================"
python3 run_comprehensive_5_test_suite.py

echo ""
echo "=== ALL SYSTEMS VERIFIED SUCCESSFULLY! ==="
