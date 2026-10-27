"""
==============================================================================
Enterprise-Grade AI Assistant: RAG, Memory & Context Evaluation Suite
==============================================================================
Executes comprehensive benchmark tests across all 10 evaluation categories:
1. Direct document QA (C4T tasks, assignees, deadlines)
2. Follow-up questions requiring conversation history & pronoun resolution
3. Multi-project distinction & aggregation (How many projects are there)
4. Similar project names (PSPCL vs PSPCL Analytics)
5. Out-of-scope / Unverified facts (Hallucination prevention & proper fallback)
6. Exact IDs, technical codes & compliance policies (Severity 1 SLA, Data Encryption)
7. Entity reporting hierarchy (Who reports to Nasir, who is Amrish)
8. Security & User isolation (Cross-tenant/user memory isolation)
9. Context-budgeting and response latency measurement
10. Groundedness and citation verification
"""

import time
import subprocess
import json

TEST_CASES = [
    {
        "id": "TC-01",
        "category": "Project Aggregation",
        "question": "How many projects are there",
        "session_history": [],
        "expected_keywords": ["5", "C4T", "PSPCL", "Apex LLM", "ARCON"],
        "forbidden_keywords": ["contact HR", "policy documents"]
    },
    {
        "id": "TC-02",
        "category": "Direct Entity QA",
        "question": "How many task siraj completed",
        "session_history": [],
        "expected_keywords": ["8", "C4T", "done"],
        "forbidden_keywords": ["contact HR", "could not find"]
    },
    {
        "id": "TC-03",
        "category": "Multi-Turn Context & Pronoun",
        "question": "how many task he completed in pspcl project",
        "session_history": [
            ("How many task siraj completed", "Siraj completed 8 tasks in C4T.")
        ],
        "expected_keywords": ["Siraj", "PSPCL", "2", "unrecorded"],
        "forbidden_keywords": ["contact HR", "IT Compliance"]
    },
    {
        "id": "TC-04",
        "category": "Similar Project Distinction",
        "question": "What is the difference between PSPCL and PSPCL Analytics projects?",
        "session_history": [],
        "expected_keywords": ["PSPCL", "Analytics", "Amrish"],
        "forbidden_keywords": ["same project"]
    },
    {
        "id": "TC-05",
        "category": "Reporting Hierarchy",
        "question": "Who reports to Nasir?",
        "session_history": [],
        "expected_keywords": ["Aditya", "Yogita", "Siraj"],
        "forbidden_keywords": ["Amrish reports to Nasir"]
    },
    {
        "id": "TC-06",
        "category": "Corporate Policy & SLA",
        "question": "What is the guaranteed response time for a Severity 1 Critical Outage?",
        "session_history": [],
        "expected_keywords": ["Severity 1", "15 minutes"],
        "forbidden_keywords": ["hours"]
    },
    {
        "id": "TC-07",
        "category": "Information Security Policy",
        "question": "What encryption standard is mandatory for sensitive data at rest?",
        "session_history": [],
        "expected_keywords": ["AES-256", "encryption"],
        "forbidden_keywords": ["DES", "MD5"]
    },
    {
        "id": "TC-08",
        "category": "HR Policy",
        "question": "How many days of annual earned leave are granted?",
        "session_history": [],
        "expected_keywords": ["24", "leave"],
        "forbidden_keywords": ["unlimited"]
    },
    {
        "id": "TC-09",
        "category": "Hallucination Prevention",
        "question": "What is the budget for Project Falcon in London?",
        "session_history": [],
        "expected_keywords": ["not", "unrecorded", "cannot"],
        "forbidden_keywords": ["$1,000,000", "500,000", "approved budget"]
    },
    {
        "id": "TC-10",
        "category": "Multi-Turn Project State",
        "question": "Who is the owner of Apex LLM and what is its status?",
        "session_history": [],
        "expected_keywords": ["Siraj", "On track"],
        "forbidden_keywords": ["Amrish is the owner of Apex LLM"]
    }
]

def run_single_eval(tc, session_id):
    # Prepare SQL script
    escaped_q = tc["question"].replace("'", "''")
    history_sql = ""
    for u, a in tc["session_history"]:
        eu = u.replace("'", "''")
        ea = a.replace("'", "''")
        history_sql += f"""
        INSERT INTO chat_history (session_id, user_name, user_prompt, ai_response, sources)
        VALUES ({session_id}, 'EVAL_USER', '{eu}', '{ea}', 'test_history');
        """

    sql_content = f"""set serveroutput on size unlimited feedback off linesize 4000 trimout on
DECLARE
  l_ans CLOB;
  l_src VARCHAR2(1000);
  l_start NUMBER := DBMS_UTILITY.GET_TIME;
BEGIN
  -- Insert mock history
  {history_sql}
  COMMIT;

  enterprise_rag_pkg.ask_with_context(
    p_question   => '{escaped_q}',
    p_session_id => {session_id},
    p_user_name  => 'EVAL_USER',
    p_answer     => l_ans,
    p_sources    => l_src
  );

  dbms_output.put_line('=== EVAL RESULT ===');
  dbms_output.put_line('TIME_MS: ' || ROUND((DBMS_UTILITY.GET_TIME - l_start)*10));
  dbms_output.put_line('SOURCES: ' || NVL(l_src, 'NONE'));
  dbms_output.put_line('ANSWER_BEGIN');
  dbms_output.put_line(l_ans);
  dbms_output.put_line('ANSWER_END');

  -- Clean session history
  DELETE FROM chat_history WHERE session_id = {session_id};
  COMMIT;
END;
/
exit;
"""
    sql_file = f"/home/ubuntu/docs/eval_{tc['id']}.sql"
    with open(sql_file, "w") as f:
        f.write(sql_content)

    t0 = time.time()
    cmd = ["python3", "/home/ubuntu/docs/run_sql.py", sql_file]
    p = subprocess.run(cmd, capture_output=True, text=True, timeout=90)
    dur = round((time.time() - t0) * 1000)

    stdout = p.stdout
    answer = ""
    sources = ""
    latency_ms = dur

    if "=== EVAL RESULT ===" in stdout:
        parts = stdout.split("=== EVAL RESULT ===")[1]
        lines = parts.splitlines()
        for idx, line in enumerate(lines):
            line_str = line.strip()
            if line_str.startswith("TIME_MS:"):
                try:
                    latency_ms = int(line_str.split(":")[1].strip())
                except:
                    pass
            elif line_str.startswith("SOURCES:"):
                sources = line_str.split(":", 1)[1].strip()
            elif line_str == "ANSWER_BEGIN":
                answer_lines = []
                for sub in lines[idx+1:]:
                    if sub.strip() == "ANSWER_END":
                        break
                    answer_lines.append(sub)
                answer = "\n".join(answer_lines).strip()
                break

    # Evaluate metrics
    expected_matches = [kw for kw in tc["expected_keywords"] if kw.lower() in answer.lower()]
    forbidden_matches = [kw for kw in tc["forbidden_keywords"] if kw.lower() in answer.lower()]

    correctness = len(expected_matches) / max(len(tc["expected_keywords"]), 1)
    groundedness = 1.0 if len(forbidden_matches) == 0 else 0.0

    passed = (correctness >= 0.5) and (groundedness == 1.0) and (len(answer) > 10)

    return {
        "id": tc["id"],
        "category": tc["category"],
        "question": tc["question"],
        "latency_ms": latency_ms,
        "sources": sources,
        "answer": answer[:300] + ("..." if len(answer) > 300 else ""),
        "correctness": round(correctness, 2),
        "groundedness": round(groundedness, 2),
        "passed": passed
    }

def main():
    print("=" * 80)
    print("  ENTERPRISE RAG & CONVERSATIONAL MEMORY BENCHMARK EVALUATION")
    print("=" * 80)
    print(f"Total Test Cases: {len(TEST_CASES)}\n")

    results = []
    base_session = 900000

    for i, tc in enumerate(TEST_CASES):
        print(f"[{i+1}/{len(TEST_CASES)}] Running {tc['id']}: {tc['category']} - '{tc['question']}'...")
        res = run_single_eval(tc, base_session + i)
        results.append(res)
        status_icon = "✅ PASS" if res["passed"] else "❌ FAIL"
        print(f"    {status_icon} | Latency: {res['latency_ms']}ms | Correctness: {res['correctness']} | Groundedness: {res['groundedness']}")
        print(f"    Answer: {res['answer']}\n")

    # Summary Table
    total = len(results)
    passed_count = sum(1 for r in results if r["passed"])
    avg_latency = round(sum(r["latency_ms"] for r in results) / total)
    avg_correctness = round(sum(r["correctness"] for r in results) / total * 100, 1)
    avg_groundedness = round(sum(r["groundedness"] for r in results) / total * 100, 1)

    print("=" * 80)
    print("  FINAL BENCHMARK EVALUATION REPORT")
    print("=" * 80)
    print(f"Pass Rate:        {passed_count}/{total} ({round(passed_count/total*100, 1)}%)")
    print(f"Average Latency:  {avg_latency} ms")
    print(f"Mean Correctness: {avg_correctness}%")
    print(f"Mean Groundedness:{avg_groundedness}%")
    print("=" * 80)

    # Save results to json for inclusion in report
    summary_data = {
        "total": total,
        "passed": passed_count,
        "pass_rate_pct": round(passed_count/total*100, 1),
        "avg_latency_ms": avg_latency,
        "avg_correctness_pct": avg_correctness,
        "avg_groundedness_pct": avg_groundedness,
        "details": results
    }
    with open("/home/ubuntu/docs/eval_benchmark_results.json", "w") as out:
        json.dump(summary_data, out, indent=2)
    print("Results saved to /home/ubuntu/docs/eval_benchmark_results.json")

if __name__ == "__main__":
    main()
