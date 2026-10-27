import json
import urllib.request
import urllib.error
import sys

def check_ollama(base_url="http://20.0.1.39:11434", model="llama3.1:8b"):
    print(f"=== 1. Checking Ollama at {base_url} for model '{model}' ===")
    
    # 1. Show existing model config
    show_req = urllib.request.Request(
        f"{base_url}/api/show",
        data=json.dumps({"name": model}).encode(),
        headers={"Content-Type": "application/json"}
    )
    try:
        with urllib.request.urlopen(show_req, timeout=10) as resp:
            data = json.loads(resp.read().decode())
            print("Current parameters:")
            print(data.get("parameters", "No parameters set (using Ollama defaults)"))
            print("\nCurrent modelfile snippet:")
            modelfile = data.get("modelfile", "")
            for line in modelfile.splitlines()[:15]:
                print("  ", line)
    except Exception as e:
        print(f"Error reading /api/show: {e}")
        return False

    # 2. Update model with num_ctx 8192 and temperature 0.0
    print(f"\n=== 2. Updating model '{model}' with num_ctx = 8192 and temperature = 0.0 ===")
    
    # Build updated modelfile
    # We base it FROM the current model
    modelfile_content = f"""FROM {model}
PARAMETER num_ctx 8192
PARAMETER temperature 0.0
PARAMETER top_p 0.9
PARAMETER stop "<|start_header_id|>"
PARAMETER stop "<|end_header_id|>"
PARAMETER stop "<|eot_id|>"
"""
    print("New Modelfile to apply:")
    print(modelfile_content)

    create_payload = {
        "name": model,
        "from": model,
        "parameters": {
            "num_ctx": 8192,
            "temperature": 0.0,
            "top_p": 0.9
        },
        "stream": False
    }

    create_req = urllib.request.Request(
        f"{base_url}/api/create",
        data=json.dumps(create_payload).encode(),
        headers={"Content-Type": "application/json"}
    )

    try:
        print("Calling /api/create (this reuses existing layers, takes 1-3 seconds)...")
        with urllib.request.urlopen(create_req, timeout=60) as resp:
            res = json.loads(resp.read().decode())
            print("Create response:", res)
    except urllib.error.HTTPError as he:
        print(f"HTTPError {he.code}: {he.read().decode()}")
        return False
    except Exception as e:
        print(f"Error calling /api/create: {e}")
        return False

    # 3. Verify updated parameters
    print(f"\n=== 3. Verifying updated parameters via /api/show ===")
    with urllib.request.urlopen(show_req, timeout=10) as resp:
        data = json.loads(resp.read().decode())
        params = data.get("parameters", "")
        print("Verified Parameters in Ollama:")
        print(params)
        
        has_num_ctx = "num_ctx" in params and "8192" in params
        has_temp = "temperature" in params and "0" in params
        if has_num_ctx and has_temp:
            print("\n>>> SUCCESS: num_ctx = 8192 and temperature = 0.0 are permanently active! <<<")
        else:
            print("\n>>> WARNING: Check parameters above, expected num_ctx 8192 and temperature 0 <<<")

    # 4. Test inference
    print(f"\n=== 4. Testing test prompt with new settings ===")
    chat_payload = {
        "model": model,
        "messages": [{"role": "user", "content": "Respond in 5 words confirming your temperature and factual grounding."}],
        "stream": False
    }
    chat_req = urllib.request.Request(
        f"{base_url}/api/chat",
        data=json.dumps(chat_payload).encode(),
        headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(chat_req, timeout=30) as resp:
        res = json.loads(resp.read().decode())
        reply = res.get("message", {}).get("content", "").strip()
        print(f"Model test response: '{reply}'")
        eval_count = res.get("eval_count", 0)
        prompt_eval_count = res.get("prompt_eval_count", 0)
        print(f"Tokens: prompt={prompt_eval_count}, eval={eval_count}")

    return True

if __name__ == "__main__":
    check_ollama()
