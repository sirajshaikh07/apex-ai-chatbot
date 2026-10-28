#!/usr/bin/env bash
set -e

cd /home/ubuntu/docs

echo "======================================================="
echo "   COMMITTING & PUSHING TO GIT"
echo "======================================================="

git status -s

echo ""
echo "[*] Adding changes to git..."
git add .gitignore *.py *.sh *.sql rag_datasets/*.txt rag_datasets/*.json 2>/dev/null || git add -A

echo "[*] Committing changes with message: 'two datasets checks'..."
git commit -m "two datasets checks" || echo "Nothing to commit or already committed."

echo "[*] Pushing to remote repository..."
git push

echo ""
echo "🎉 Successfully committed and pushed to git!"
