#!/usr/bin/env python3
import requests
import json
import time

url = "http://127.0.0.1:8080/api/chat/stream"
payload = {
    "question": "What is the probationary period for new appointments and by how much can it be extended?",
    "session_id": "999888",
    "user_name": "STREAM_TEST"
}

print(f"Connecting to {url}...")
t0 = time.time()
ttft = None

try:
    with requests.post(url, json=payload, stream=True, timeout=60) as resp:
        print(f"HTTP Status: {resp.status_code}")
        for line in resp.iter_lines(decode_unicode=True):
            if line:
                if line.startswith("data: "):
                    data = json.loads(line[6:])
                    if "token" in data:
                        if ttft is None:
                            ttft = (time.time() - t0) * 1000
                            print(f"\n⚡ Time To First Token (TTFT): {ttft:.1f}ms\n--- Streamed Content ---")
                        print(data["token"], end="", flush=True)
                    elif data.get("done"):
                        total_ms = (time.time() - t0) * 1000
                        print(f"\n\n--- Stream Complete! ---")
                        print(f"Total Elapsed: {total_ms:.1f}ms")
                        print(f"Source:        {data.get('sources')}")
                        print(f"Msg ID:        {data.get('msg_id')}")
                        break
except Exception as e:
    print(f"Error: {e}")
