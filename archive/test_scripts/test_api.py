import urllib.request
import json

def test_chat(query):
    url = "http://127.0.0.1:8080/ords/aidemo/api/chat"
    headers = {"Content-Type": "application/json"}
    data = json.dumps({"question": query}).encode("utf-8")
    
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            body = resp.read().decode("utf-8")
            res = json.loads(body)
            print(f"=== Q: {query} ===")
            print(f"Answer:  {res.get('answer')}")
            print(f"Sources: {res.get('sources')}\n")
    except Exception as e:
        print(f"Error querying {url}: {e}")

if __name__ == "__main__":
    test_chat("How are you")
    test_chat("Where are you from")
    test_chat("What is the guaranteed response time for a Severity 1 Critical Outage?")
