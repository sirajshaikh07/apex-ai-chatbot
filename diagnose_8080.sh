#!/usr/bin/env bash
set -uo pipefail

echo "=============================================="
echo "  APEX / ORDS Port 8080 Diagnostic & Fix"
echo "=============================================="

echo ""
echo "[1] Checking ORDS service status and listening port..."
systemctl is-active ords.service || true
sudo ss -tlnp | grep 8080 || echo "WARNING: Port 8080 not found in ss!"

echo ""
echo "[2] Testing local HTTP responses..."
echo "--- curl http://127.0.0.1:8080/ords/apex ---"
curl -sI http://127.0.0.1:8080/ords/apex | head -n 8 || true

echo "--- curl http://20.0.1.39:8080/ords/apex ---"
curl -sI http://20.0.1.39:8080/ords/apex | head -n 8 || true

echo ""
echo "[3] Checking OS Firewalls (firewalld & iptables)..."
echo "--- Firewalld Public Zone ---"
sudo firewall-cmd --list-all || true

echo ""
echo "--- Checking Oracle Cloud Default iptables Rules ---"
sudo iptables -L INPUT -n -v --line-numbers | head -n 15

# Ensure port 8080 is ACCEPTED in iptables before any REJECT rule
echo ""
echo "[4] Applying OS Firewall Fix for Port 8080..."
# Add to firewalld permanently
sudo firewall-cmd --permanent --add-port=8080/tcp >/dev/null 2>&1 || true
sudo firewall-cmd --reload >/dev/null 2>&1 || true

# Add to top of iptables INPUT chain so OCI default reject rule doesn't block it
if ! sudo iptables -C INPUT -p tcp --dport 8080 -j ACCEPT 2>/dev/null; then
  echo "Inserting ACCEPT rule for port 8080 into iptables INPUT chain..."
  sudo iptables -I INPUT 1 -p tcp --dport 8080 -j ACCEPT
else
  echo "Port 8080 is already accepted in iptables."
fi

echo ""
echo "[5] Verifying iptables top rules:"
sudo iptables -L INPUT -n -v --line-numbers | head -n 8

echo ""
echo "=============================================="
echo "  OS-level checks and firewall fix applied!"
echo "=============================================="
