#!/usr/bin/env python3
import json
import urllib.request
import urllib.error
import time

API_URL = "http://127.0.0.1:8080/ords/aidemo/api/chat"

print(f"\nTarget REST Endpoint: {API_URL}")
print("=" * 65)

test_cases = [
    {
        "name": "Cloud SLA (Severity 1)",
        "question": "What is the guaranteed response time for a Severity 1 Critical Outage?",
        "expected_keywords": ["15 minutes", "under 15"],
        "expected_source": "01_cloud_sla.txt"
    },
    {
        "name": "Leave Policy (Earned Leaves)",
        "question": "How many days of annual earned leave are granted each calendar year?",
        "expected_keywords": ["18"],
        "expected_source": "02_leave_policy.txt"
    },
    {
        "name": "Data Security (Encryption at Rest)",
        "question": "What encryption standard is mandatory for sensitive data at rest?",
        "expected_keywords": ["AES-256"],
        "expected_source": "03_data_security.txt"
    },
    {
        "name": "Expense Reimbursement (Deadline)",
        "question": "What is the submission deadline for travel expense reimbursement claims?",
        "expected_keywords": ["15"],
        "expected_source": "04_expense_policy.txt"
    },
    {
        "name": "Support Escalation (War Room)",
        "question": "When is an Executive War Room opened if an outage is unresolved?",
        "expected_keywords": ["60"],
        "expected_source": "05_support_escalation.txt"
    },
    {
        "name": "Anti-Hallucination Guardrail (Out-of-Domain)",
        "question": "What is the corporate pet policy for bringing dogs to the office?",
        "expected_keywords": ["not available", "Information not available"],
        "expected_source": ""
    }
]

passed = 0
total = len(test_cases)

for i, tc in enumerate(test_cases, 1):
    payload = json.dumps({"question": tc["question"]}).encode("utf-8")
    req = urllib.request.Request(
        API_URL,
        data=payload,
        headers={"Content-Type": "application/json"}
    )
    
    t0 = time.time()
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            elapsed = time.time() - t0
            status_code = resp.getcode()
            body = resp.read().decode("utf-8")
            data = json.loads(body)
            
            answer = data.get("answer", "")
            sources = data.get("sources", "")
            
            # Check keywords
            kw_match = any(kw.lower() in answer.lower() for kw in tc["expected_keywords"])
            
            print(f"\n[Test {i}/{total}] {tc['name']}")
            print(f"  Q: {tc['question']}")
            print(f"  Status: HTTP {status_code} ({elapsed:.2f}s)")
            print(f"  Sources: {sources}")
            print(f"  A: {answer.strip()[:140]}...")
            
            if kw_match and status_code == 200:
                print(f"  Result: ✅ PASS")
                passed += 1
            else:
                print(f"  Result: ❌ FAIL (Expected keywords: {tc['expected_keywords']})")
                
    except urllib.error.HTTPError as e:
        print(f"\n[Test {i}/{total}] {tc['name']} -> HTTP Error {e.code}: {e.read().decode('utf-8')}")
    except Exception as e:
        print(f"\n[Test {i}/{total}] {tc['name']} -> Exception: {e}")

print("\n" + "=" * 65)
print(f"Final REST API Test Score: {passed}/{total} Passed")
if passed == total:
    print("🎉 ALL ENTERPRISE API TESTS PASSED SUCCESSFULLY!")
else:
    print(f"Score: {passed}/{total}. Please check failed test cases.")
