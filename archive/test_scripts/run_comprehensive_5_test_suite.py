import os
import sys
import subprocess
import json
import time

def run_sql_query(sql_text, title):
    print(f"\n======================================================================")
    print(f"RUNNING: {title}")
    print(f"======================================================================")
    tmp_file = "/home/ubuntu/docs/temp_test_exec.sql"
    with open(tmp_file, "w", encoding="utf-8") as f:
        f.write(f"""SET SERVEROUTPUT ON SIZE UNLIMITED;
SET LINESIZE 250;
ALTER SESSION SET CURRENT_SCHEMA = AIDEMO;

DECLARE
  l_ans CLOB;
  l_src VARCHAR2(1000);
BEGIN
  enterprise_rag_pkg.ask_with_context(
    p_question   => '{sql_text}',
    p_session_id => 999111,
    p_user_name  => 'ADMIN',
    p_answer     => l_ans,
    p_sources    => l_src
  );
  DBMS_OUTPUT.PUT_LINE('SOURCES: ' || l_src);
  DBMS_OUTPUT.PUT_LINE('ANSWER:');
  DBMS_OUTPUT.PUT_LINE(l_ans);
END;
/
EXIT;
""")
    t0 = time.time()
    res = subprocess.run([sys.executable, "run_sql.py", "temp_test_exec.sql"], capture_output=True, text=True)
    elapsed = time.time() - t0
    print(res.stdout)
    if res.stderr:
        print("STDERR:", res.stderr)
    print(f"Elapsed Time: {elapsed:.1f}s")
    return res.stdout

def run_ords_rest_test():
    print(f"\n======================================================================")
    print("RUNNING EXAMPLE 5: ORDS REST API MULTI-TURN CHAT (Live HTTP POST)")
    print(f"======================================================================")
    import urllib.request
    
    url = "http://localhost:8080/ords/aidemo/api/chat"
    sess_id = 888777
    
    # Turn 1
    t1_payload = {
        "question": "Who is the owner of Apex LLM project?",
        "session_id": sess_id,
        "user_name": "API_TEST_CLIENT"
    }
    print(f">>> TURN 1 POST: {t1_payload['question']} (session: {sess_id})")
    req = urllib.request.Request(
        url,
        data=json.dumps(t1_payload).encode('utf-8'),
        headers={'Content-Type': 'application/json'},
        method='POST'
    )
    try:
        t0 = time.time()
        with urllib.request.urlopen(req, timeout=60) as resp:
            data1 = json.loads(resp.read().decode('utf-8'))
            print(f"Status: {data1.get('status')} | Elapsed: {time.time()-t0:.1f}s")
            print("Turn 1 Answer:\n" + data1.get('answer', ''))
    except Exception as e:
        print(f"Turn 1 Error: {e}")

    # Turn 2: Follow-up using pronoun "he" and "that project"
    t2_payload = {
        "question": "What is the status of that project and how many tasks does he have in it?",
        "session_id": sess_id,
        "user_name": "API_TEST_CLIENT"
    }
    print(f"\n>>> TURN 2 POST: {t2_payload['question']} (session: {sess_id})")
    req2 = urllib.request.Request(
        url,
        data=json.dumps(t2_payload).encode('utf-8'),
        headers={'Content-Type': 'application/json'},
        method='POST'
    )
    try:
        t0 = time.time()
        with urllib.request.urlopen(req2, timeout=60) as resp:
            data2 = json.loads(resp.read().decode('utf-8'))
            print(f"Status: {data2.get('status')} | Elapsed: {time.time()-t0:.1f}s")
            print("Turn 2 Answer:\n" + data2.get('answer', ''))
    except Exception as e:
        print(f"Turn 2 Error: {e}")

def main():
    print("======================================================================")
    print("STARTING COMPREHENSIVE 5-EXAMPLE VALIDATION SUITE")
    print("======================================================================")

    # 1. Example 1: Attribution & Precision Test
    run_sql_query("Give me title of all task siraj completed", "EXAMPLE 1: Attribution & Precision (Siraj Completed Tasks)")

    # 2. Example 2: Team & Reporting Hierarchy
    run_sql_query("Who reports to Nasir and who reports to Amrish?", "EXAMPLE 2: Reporting Hierarchy & Non-Task Knowledge")

    # 3. Example 3: Blocked / Overdue Items in C4T
    run_sql_query("Which tasks are currently blocked or overdue in C4T project?", "EXAMPLE 3: Blocked & Overdue Project Items")

    # 4. Example 4: Aditya's Tasks Across Projects
    run_sql_query("What tasks are assigned to Aditya across C4T and PSPCL?", "EXAMPLE 4: Cross-Project Tasks for Aditya")

    # 5. Example 5: Live ORDS REST API Multi-Turn Chat
    run_ords_rest_test()

    print("\n======================================================================")
    print("ALL 5 EXAMPLES COMPLETED.")
    print("======================================================================")

if __name__ == "__main__":
    main()
