import subprocess
import time

test_cases = [
    {
        "id": "TC-NEW-01",
        "category": "Priority 3 & 4: Hinglish Query Resolver + 150-word Chunks",
        "query": "Danish sheikh ki umar kitni hai aur wo kahan rehta hai?",
        "expected_intent": "Age 31, City Pune, Maharashtra from tamanna shaikh.pdf"
    },
    {
        "id": "TC-NEW-02",
        "category": "Priority 3 & 4: Hinglish Query Resolver + 150-word Chunks",
        "query": "Safa ke pitaji ka naam aur unka address batao",
        "expected_intent": "Father Himmatkha Navajkhan Pathan, Address Bembli Osmanabad from bio data .pdf"
    },
    {
        "id": "TC-NEW-03",
        "category": "Priority 3 & 4: Hinglish Query Resolver + 150-word Chunks",
        "query": "Danish ke father kya kaam karte hain?",
        "expected_intent": "Father M.B.B.S, M.D (Medicine), Medical Specialist from tamanna shaikh.pdf"
    },
    {
        "id": "TC-NEW-04",
        "category": "Priority 3 & 4: Hinglish Query Resolver + 150-word Chunks",
        "query": "Safa ki hobbies aur education kya hai?",
        "expected_intent": "12th Commerce, Islamic Studies, Cooking, Household Management"
    },
    {
        "id": "TC-NEW-05",
        "category": "Priority 2: Grounding Gatekeeper (Instant Out-of-Domain Block)",
        "query": "World Cup 2024 kisne jeeta?",
        "expected_intent": "0.01s Gatekeeper rejection without LLM call"
    },
    {
        "id": "TC-NEW-06",
        "category": "Priority 2: Grounding Gatekeeper (Instant Out-of-Domain Block)",
        "query": "Biryani banane ki recipe batao",
        "expected_intent": "0.01s Gatekeeper rejection without LLM call"
    },
    {
        "id": "TC-NEW-07",
        "category": "Priority 2: Grounding Gatekeeper (High Cosine Distance Block)",
        "query": "What is the capital city of Japan?",
        "expected_intent": "0.01s Gatekeeper rejection (Distance >= 0.82)"
    },
    {
        "id": "TC-NEW-08",
        "category": "Priority 1: Zero Hallucination Guardrail (temp = 0.0)",
        "query": "What is Danish sheikh passport number and car model?",
        "expected_intent": "Factual refusal stating passport/car is not mentioned in documents"
    }
]

print("==========================================================================")
print("  ENTERPRISE RAG: COMPREHENSIVE SUITE TESTING (ALL PRIORITIES 1, 2, 3, 4) ")
print("==========================================================================")

for tc in test_cases:
    sql = f"""set define off serveroutput on size unlimited feedback off linesize 200 pagesize 0 trimout on
DECLARE
  l_start NUMBER := DBMS_UTILITY.GET_TIME;
  l_ans CLOB;
  l_src VARCHAR2(500);
  l_ms  NUMBER;
BEGIN
  enterprise_rag_pkg.ask_with_context(
    p_question   => '{tc["query"].replace("'", "''")}',
    p_session_id => 88888,
    p_user_name  => 'SUITE_TESTER',
    p_answer     => l_ans,
    p_sources    => l_src
  );
  l_ms := ROUND((DBMS_UTILITY.GET_TIME - l_start) * 10);
  dbms_output.put_line('LATENCY_MS:' || l_ms);
  dbms_output.put_line('SOURCES:' || NVL(l_src, 'NONE'));
  dbms_output.put_line('ANSWER:' || l_ans);
END;
/
exit;
"""
    with open('/home/ubuntu/docs/temp_suite_test.sql', 'w') as f:
        f.write(sql)

    t0 = time.time()
    p = subprocess.run(["python3", "/home/ubuntu/docs/run_sql.py", "temp_suite_test.sql"], capture_output=True, text=True, timeout=90)
    dur = time.time() - t0

    latency_ms = "N/A"
    sources = "N/A"
    answer = ""
    for line in p.stdout.splitlines():
        if line.startswith("LATENCY_MS:"):
            latency_ms = line.split(":", 1)[1].strip()
        elif line.startswith("SOURCES:"):
            sources = line.split(":", 1)[1].strip()
        elif line.startswith("ANSWER:"):
            answer = line.split(":", 1)[1].strip()
        elif answer and not line.startswith("===") and not line.startswith("Connecting"):
            answer += "\n" + line.strip()

    print(f"\n--------------------------------------------------------------------------")
    print(f"[{tc['id']}] {tc['category']}")
    print(f"QUERY:    \"{tc['query']}\"")
    print(f"EXPECTED: {tc['expected_intent']}")
    print(f"LATENCY:  DB={latency_ms} ms (Total Process={dur:.2f}s) | Sources: {sources}")
    print(f"RESPONSE:\n{answer.strip()}")

print("\n==========================================================================")
print("  COMPREHENSIVE SUITE TESTING COMPLETE")
print("==========================================================================")
