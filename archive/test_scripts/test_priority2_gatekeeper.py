import subprocess
import time

queries = [
    ("Cricket score", "IRRELEVANT"),
    ("Aaj ka mausam kaisa hai?", "IRRELEVANT"),
    ("What is the refund policy for cancellation of airline tickets?", "IRRELEVANT"),
    ("Tell me about stock prices", "IRRELEVANT"),
    ("Who is Rohit Labade and where is he placed?", "RELEVANT"),
    ("What is Safa Pathan age and contact number?", "RELEVANT")
]

print("=================================================================")
print("  PRIORITY 2: SIMILARITY SCORE & GROUNDING GATEKEEPER TEST")
print("=================================================================")

for q, expected in queries:
    sql = f"""set serveroutput on size unlimited feedback off linesize 200 pagesize 0 trimout on
DECLARE
  l_start NUMBER := DBMS_UTILITY.GET_TIME;
  l_ans CLOB;
  l_src VARCHAR2(500);
  l_ms  NUMBER;
BEGIN
  enterprise_rag_pkg.ask_with_context(
    p_question   => '{q.replace("'", "''")}',
    p_session_id => 99991,
    p_user_name  => 'GATE_TESTER',
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
    with open('/home/ubuntu/docs/temp_gate_test.sql', 'w') as f:
        f.write(sql)

    t0 = time.time()
    p = subprocess.run(["python3", "/home/ubuntu/docs/run_sql.py", "temp_gate_test.sql"], capture_output=True, text=True, timeout=60)
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
            answer += " " + line.strip()

    print(f"\n[QUERY] {q}")
    print(f"  Type: {expected} | DB Latency: {latency_ms} ms (Total Process: {dur:.2f}s)")
    print(f"  Sources: {sources}")
    print(f"  Answer: {answer[:180]}..." if len(answer) > 180 else f"  Answer: {answer}")
