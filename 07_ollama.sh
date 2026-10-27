#!/usr/bin/env bash
set -euo pipefail

echo "=============================================="
echo "  Phase 7: Local LLM with Ollama Setup"
echo "=============================================="

source /home/ubuntu/project/values.env
source /home/ubuntu/.secrets.env

VM1_IP="${VM1_IP:-20.0.1.130}"
VM2_IP="${VM2_IP:-20.0.1.39}"
CHAT_MODEL="${CHAT_MODEL:-llama3.1:8b}"

echo ""
echo "[1] Installing native Ollama via official installer..."
curl -fsSL https://ollama.com/install.sh | sh

echo ""
echo "[2] Configuring systemd override for private IP binding & context length..."
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo tee /etc/systemd/system/ollama.service.d/override.conf > /dev/null <<EOF
[Service]
Environment="OLLAMA_HOST=${VM2_IP}:11434"
Environment="OLLAMA_CONTEXT_LENGTH=8192"
Environment="OLLAMA_KEEP_ALIVE=30m"
EOF

sudo systemctl daemon-reload
sudo systemctl enable ollama
sudo systemctl restart ollama

# Set in bashrc if not already present
if ! grep -q "OLLAMA_HOST=" /home/ubuntu/.bashrc; then
  echo "export OLLAMA_HOST=${VM2_IP}:11434" >> /home/ubuntu/.bashrc
fi
export OLLAMA_HOST="${VM2_IP}:11434"

echo ""
echo "[3] Verifying Ollama service status and port binding..."
sleep 3
systemctl is-active ollama
sudo ss -tlnp | grep 11434 || echo "WARNING: Port 11434 not listening yet!"

echo ""
echo "[4] Pulling chat model: ${CHAT_MODEL} (tools-capable)..."
ollama pull "${CHAT_MODEL}"
ollama list

echo ""
echo "[5] Configuring firewalld and iptables (allowing 11434 ONLY from VM1: ${VM1_IP})..."
sudo firewall-cmd --permanent --add-rich-rule="rule family=\"ipv4\" source address=\"${VM1_IP}/32\" port port=\"11434\" protocol=\"tcp\" accept" || true
sudo firewall-cmd --reload || true

# Also ensure iptables allows VM1 to 11434
if ! sudo iptables -C INPUT -p tcp -s "${VM1_IP}" --dport 11434 -j ACCEPT 2>/dev/null; then
  sudo iptables -I INPUT 1 -p tcp -s "${VM1_IP}" --dport 11434 -j ACCEPT
fi

echo ""
echo "[6] Running validation tests against Ollama..."
python3 - << 'PYEOF'
import json, urllib.request, time, os

base_url = f"http://{os.environ.get('VM2_IP', '20.0.1.39')}:11434"
model = os.environ.get('CHAT_MODEL', 'llama3.1:8b')

print(f"Testing endpoint: {base_url} with model {model}...")

# 1. GET /api/tags
req = urllib.request.Request(f"{base_url}/api/tags")
with urllib.request.urlopen(req) as resp:
    tags = json.loads(resp.read().decode())
    print("GET /api/tags models:", [m['name'] for m in tags.get('models', [])])

# 2. POST /api/chat non-streaming
payload = {
    "model": model,
    "messages": [{"role": "user", "content": "Reply with the single word OK"}],
    "stream": False
}
req = urllib.request.Request(
    f"{base_url}/api/chat",
    data=json.dumps(payload).encode(),
    headers={"Content-Type": "application/json"}
)
t0 = time.time()
with urllib.request.urlopen(req) as resp:
    res = json.loads(resp.read().decode())
    elapsed = time.time() - t0
    reply = res.get('message', {}).get('content', '').strip()
    eval_count = res.get('eval_count', 0)
    eval_dur = res.get('eval_duration', 1)
    tok_sec = (eval_count / eval_dur * 1e9) if eval_dur > 0 else 0
    print(f"Chat response: '{reply}' in {elapsed:.2f}s ({tok_sec:.2f} tokens/s)")

# 3. POST /v1/chat/completions (OpenAI compatible)
req_oai = urllib.request.Request(
    f"{base_url}/v1/chat/completions",
    data=json.dumps(payload).encode(),
    headers={"Content-Type": "application/json"}
)
with urllib.request.urlopen(req_oai) as resp:
    res_oai = json.loads(resp.read().decode())
    content = res_oai['choices'][0]['message']['content'].strip()
    print(f"/v1/chat/completions response: '{content}'")

# 4. Tool calling test (3 times)
tools = [{
    "type": "function",
    "function": {
        "name": "get_weather",
        "description": "Get current weather for a city",
        "parameters": {
            "type": "object",
            "properties": {"city": {"type": "string"}},
            "required": ["city"]
        }
    }
}]
tool_payload = {
    "model": model,
    "messages": [{"role": "user", "content": "What is the weather in Pune?"}],
    "stream": False,
    "tools": tools
}
tool_success = 0
for i in range(1, 4):
    req_t = urllib.request.Request(
        f"{base_url}/api/chat",
        data=json.dumps(tool_payload).encode(),
        headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req_t) as resp:
        res_t = json.loads(resp.read().decode())
        tc = res_t.get('message', {}).get('tool_calls', [])
        has_tc = len(tc) > 0
        if has_tc: tool_success += 1
        print(f"Tool call test {i}/3: tool_calls present? {has_tc}")

print(f"\nTool calling success rate: {tool_success}/3")
PYEOF

echo ""
echo "=== Phase 7 Local LLM Setup Complete! ==="
