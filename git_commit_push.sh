#!/usr/bin/env bash
set -e

cd /home/ubuntu/docs

echo "======================================================="
echo "   COMMITTING & PUSHING TO GIT"
echo "======================================================="

git status -s

MSG="${1:-streaming_rag.service naye 5 fixes ke sath successfully restart ho chuki hai!}"

echo "[*] Adding changes to git..."
git add -A

echo "[*] Committing changes with message: '$MSG'..."
git commit -m "$MSG" || echo "Nothing to commit or already committed."

echo "[*] Pushing to remote repository..."
git push

echo ""
echo "🎉 Successfully committed and pushed to git!"
