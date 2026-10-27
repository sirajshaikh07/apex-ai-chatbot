#!/usr/bin/env python3
import requests
import json
import time

url = "http://127.0.0.1:8080/api/chat/stream"
payload = {
    "question": "What is the policy for medical leave and certificates?",
    "session_id": "123",
    "user_name": "test"
}

print(f"Testing POST {url}...")
try:
    resp = requests.post(url, json=payload, stream=True, timeout=10)
    print(f"Status Code: {resp.status_code}")
    print(f"Headers: {dict(resp.headers)}")
    for line in resp.iter_lines(decode_unicode=True):
        if line:
            print("LINE:", line)
            if "done" in line:
                break
except Exception as e:
    print(f"ERROR: {e}")
