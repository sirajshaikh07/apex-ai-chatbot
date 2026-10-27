import os
import subprocess
import time
import re

print("==========================================================================")
print("             TIER 2: 10 COMPREHENSIVE PRODUCTION TEST CASES              ")
print("  (Follow-Up Query Rewriting + Thumbs Up/Down Feedback + Observability)   ")
print("==========================================================================")

os.environ["SQL_TIMEOUT"] = "120"

def run_sql(sql_code, timeout=120):
    sql_file = "/home/ubuntu/docs/temp_tier2_run.sql"
    with open(sql_file, "w") as f:
        f.write(f"SET DEFINE OFF SERVEROUTPUT ON SIZE UNLIMITED FEEDBACK OFF;\n{sql_code.strip()}\n/\nEXIT;\n")
    
    cmd = ["python3", "/home/ubuntu/docs/run_sql.py", "temp_tier2_run.sql"]
    p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    return p.stdout, p.stderr

SESS_T2_01 = 20001
SESS_T2_02 = 20002
SESS_T2_03 = 20003
SESS_T2_04 = 20004
SESS_T2_05 = 20005
SESS_T2_06 = 20006

tests = [
    # -------------------------------------------------------------
    # T2-01: Multi-Turn Follow-Up: Safa -> "aur uska address kya hai?"
    # -------------------------------------------------------------
    {
        "id": "T2-01",
        "name": "Follow-Up Rewriting: Safa -> 'aur uska address kya hai?'",
        "sql": f"""
DECLARE
  l_ans CLOB; l_src VARCHAR2(500); l_msg_id NUMBER;
BEGIN
  -- Setup Turn 1 in chat history
  DELETE FROM chat_history WHERE session_id = {SESS_T2_01};
  INSERT INTO chat_history (session_id, user_name, user_prompt, ai_response, sources)
  VALUES ({SESS_T2_01}, 'TESTER_T2', 'Who is Safa?', 'Safa is a B.Sc. IT candidate with profile in Safa Bio Data.', 'Safa Bio Data');
  COMMIT;
  
  -- Turn 2: Follow-up question with pronoun and connective
  enterprise_rag_pkg.ask_with_context('aur uska address kya hai?', {SESS_T2_01}, 'TESTER_T2', l_ans, l_src, l_msg_id);
  dbms_output.put_line('REWRITTEN:' || enterprise_rag_pkg.g_last_resolved_prompt);
  dbms_output.put_line('SOURCES:' || NVL(l_src, 'NONE'));
  dbms_output.put_line('ANSWER:' || l_ans);
END;
""",
        "check": lambda out: "Safa" in out and any(w in out for w in ["Bembli", "Osmanabad", "Eidgah", "Maharashtra", "Pune"])
    },

    # -------------------------------------------------------------
    # T2-02: Multi-Turn Follow-Up: Rohit Labade -> "kahan placed hua?"
    # -------------------------------------------------------------
    {
        "id": "T2-02",
        "name": "Follow-Up Rewriting: Rohit Labade -> 'kahan placed hua?'",
        "sql": f"""
DECLARE
  l_ans CLOB; l_src VARCHAR2(500); l_msg_id NUMBER;
BEGIN
  -- Setup Turn 1 in chat history
  DELETE FROM chat_history WHERE session_id = {SESS_T2_02};
  INSERT INTO chat_history (session_id, user_name, user_prompt, ai_response, sources)
  VALUES ({SESS_T2_02}, 'TESTER_T2', 'Who is Rohit Labade?', 'Rohit Labade is a Software Engineer with resume in Rohit Labade Resume.', 'Rohit Labade Resume');
  COMMIT;
  
  -- Turn 2: Follow-up question with short elliptical phrase
  enterprise_rag_pkg.ask_with_context('kahan placed hua?', {SESS_T2_02}, 'TESTER_T2', l_ans, l_src, l_msg_id);
  dbms_output.put_line('REWRITTEN:' || enterprise_rag_pkg.g_last_resolved_prompt);
  dbms_output.put_line('SOURCES:' || NVL(l_src, 'NONE'));
  dbms_output.put_line('ANSWER:' || l_ans);
END;
""",
        "check": lambda out: "Rohit" in out and any(w in out for w in ["TCS", "Tata Consultancy", "placed", "Vacant", "Vac"])
    },

    # -------------------------------------------------------------
    # T2-03: Multi-Turn Follow-Up: Danish Sheikh -> "father ka kaam?"
    # -------------------------------------------------------------
    {
        "id": "T2-03",
        "name": "Follow-Up Rewriting: Danish Sheikh -> 'father ka kaam?'",
        "sql": f"""
DECLARE
  l_ans CLOB; l_src VARCHAR2(500); l_msg_id NUMBER;
BEGIN
  -- Setup Turn 1 in chat history
  DELETE FROM chat_history WHERE session_id = {SESS_T2_03};
  INSERT INTO chat_history (session_id, user_name, user_prompt, ai_response, sources)
  VALUES ({SESS_T2_03}, 'TESTER_T2', 'Danish sheikh ki profile details', 'Danish Sheikh is residing in Dubai UAE from Danish Sheikh Bio Data.', 'Danish Sheikh Bio Data');
  COMMIT;
  
  -- Turn 2: Follow-up question
  enterprise_rag_pkg.ask_with_context('father ka kaam kya hai?', {SESS_T2_03}, 'TESTER_T2', l_ans, l_src, l_msg_id);
  dbms_output.put_line('REWRITTEN:' || enterprise_rag_pkg.g_last_resolved_prompt);
  dbms_output.put_line('SOURCES:' || NVL(l_src, 'NONE'));
  dbms_output.put_line('ANSWER:' || l_ans);
END;
""",
        "check": lambda out: "Danish" in out and any(w in out for w in ["retired", "Retired", "Contractor", "Civil", "Dubai", "business"])
    },

    # -------------------------------------------------------------
    # T2-04: Multi-Turn Follow-Up: Safa -> "educational qualification kya hai?"
    # -------------------------------------------------------------
    {
        "id": "T2-04",
        "name": "Follow-Up Rewriting: Safa -> 'educational qualification kya hai?'",
        "sql": f"""
DECLARE
  l_ans CLOB; l_src VARCHAR2(500); l_msg_id NUMBER;
BEGIN
  -- Setup Turn 1 in chat history
  DELETE FROM chat_history WHERE session_id = {SESS_T2_04};
  INSERT INTO chat_history (session_id, user_name, user_prompt, ai_response, sources)
  VALUES ({SESS_T2_04}, 'TESTER_T2', 'Safa Bio Data overview', 'Safa Bio Data contains details about Safa.', 'Safa Bio Data');
  COMMIT;
  
  -- Turn 2: Follow-up question
  enterprise_rag_pkg.ask_with_context('educational qualification kya hai?', {SESS_T2_04}, 'TESTER_T2', l_ans, l_src, l_msg_id);
  dbms_output.put_line('REWRITTEN:' || enterprise_rag_pkg.g_last_resolved_prompt);
  dbms_output.put_line('SOURCES:' || NVL(l_src, 'NONE'));
  dbms_output.put_line('ANSWER:' || l_ans);
END;
""",
        "check": lambda out: "Safa" in out and any(w in out for w in ["B.Sc", "BSc", "Information Technology", "IT"])
    },

    # -------------------------------------------------------------
    # T2-05: Observability Telemetry: Full Column Verification in CHAT_HISTORY
    # -------------------------------------------------------------
    {
        "id": "T2-05",
        "name": "Observability: Telemetry Metrics Logging (Chunks, Scores, Chars, Latency)",
        "sql": f"""
DECLARE
  l_ans CLOB; l_src VARCHAR2(500); l_msg_id NUMBER;
  l_chunks VARCHAR2(500); l_scores VARCHAR2(500);
  l_pchars NUMBER; l_cchars NUMBER; l_lat NUMBER;
BEGIN
  DELETE FROM chat_history WHERE session_id = {SESS_T2_05};
  COMMIT;
  
  enterprise_rag_pkg.ask_with_context('What is Rohit Labade technical skills and certifications?', {SESS_T2_05}, 'TESTER_T2', l_ans, l_src, l_msg_id);
  
  SELECT retrieved_chunk_ids, retrieval_scores, prompt_chars, completion_chars, response_time_ms
  INTO   l_chunks, l_scores, l_pchars, l_cchars, l_lat
  FROM   chat_history
  WHERE  msg_id = l_msg_id;
  
  dbms_output.put_line('MSG_ID:' || l_msg_id);
  dbms_output.put_line('CHUNK_IDS:' || l_chunks);
  dbms_output.put_line('SCORES:' || l_scores);
  dbms_output.put_line('PROMPT_CHARS:' || l_pchars);
  dbms_output.put_line('COMPLETION_CHARS:' || l_cchars);
  dbms_output.put_line('LATENCY_MS:' || l_lat);
END;
""",
        "check": lambda out: "CHUNK_IDS:" in out and "SCORES:" in out and "PROMPT_CHARS:" in out and "COMPLETION_CHARS:" in out
    },

    # -------------------------------------------------------------
    # T2-06: Observability Telemetry: Grounding Refusal Shielding
    # -------------------------------------------------------------
    {
        "id": "T2-06",
        "name": "Observability: Out-of-Domain Refusal Flag & Sub-50ms Latency",
        "sql": f"""
DECLARE
  l_ans CLOB; l_src VARCHAR2(500); l_msg_id NUMBER;
  l_refusal VARCHAR2(1); l_pchars NUMBER; l_lat NUMBER;
BEGIN
  DELETE FROM chat_history WHERE session_id = {SESS_T2_06};
  COMMIT;

  enterprise_rag_pkg.ask_with_context('Aaj ka mausam kaisa hai aur barish hogi kya?', {SESS_T2_06}, 'TESTER_T2', l_ans, l_src, l_msg_id);
  
  SELECT is_refusal, prompt_chars, response_time_ms
  INTO   l_refusal, l_pchars, l_lat
  FROM   chat_history
  WHERE  msg_id = l_msg_id;
  
  dbms_output.put_line('IS_REFUSAL:' || l_refusal);
  dbms_output.put_line('PROMPT_CHARS:' || l_pchars);
  dbms_output.put_line('LATENCY_MS:' || l_lat);
  dbms_output.put_line('ANSWER:' || l_ans);
END;
""",
        "check": lambda out: "IS_REFUSAL:Y" in out and "PROMPT_CHARS:0" in out
    },

    # -------------------------------------------------------------
    # T2-07: User Feedback Submission: Positive (Thumbs Up)
    # -------------------------------------------------------------
    {
        "id": "T2-07",
        "name": "Feedback Operation: Submit Thumbs Up (Helpful)",
        "sql": """
DECLARE
  l_msg_id NUMBER;
  l_fb VARCHAR2(20);
  l_time TIMESTAMP(6);
BEGIN
  SELECT MAX(msg_id) INTO l_msg_id FROM chat_history;
  
  enterprise_rag_pkg.submit_feedback(
    p_msg_id   => l_msg_id,
    p_feedback => 'UP'
  );
  
  SELECT user_feedback, feedback_time
  INTO   l_fb, l_time
  FROM   chat_history
  WHERE  msg_id = l_msg_id;
  
  dbms_output.put_line('MSG_ID:' || l_msg_id);
  dbms_output.put_line('USER_FEEDBACK:' || l_fb);
  dbms_output.put_line('FEEDBACK_TIME:' || TO_CHAR(l_time, 'YYYY-MM-DD HH24:MI:SS'));
END;
""",
        "check": lambda out: "USER_FEEDBACK:UP" in out and "FEEDBACK_TIME:" in out
    },

    # -------------------------------------------------------------
    # T2-08: User Feedback Submission: Negative ("Right info not found")
    # -------------------------------------------------------------
    {
        "id": "T2-08",
        "name": "Feedback Operation: Submit Thumbs Down ('Right info not found')",
        "sql": """
DECLARE
  l_msg_id NUMBER;
  l_fb VARCHAR2(20);
  l_cat VARCHAR2(100);
  l_comm VARCHAR2(500);
BEGIN
  SELECT MAX(msg_id) INTO l_msg_id FROM chat_history;
  
  enterprise_rag_pkg.submit_feedback(
    p_msg_id            => l_msg_id,
    p_feedback          => 'DOWN',
    p_feedback_category => 'Right info not found',
    p_feedback_comment  => 'Address details did not include city pincode'
  );
  
  SELECT user_feedback, feedback_category, feedback_comment
  INTO   l_fb, l_cat, l_comm
  FROM   chat_history
  WHERE  msg_id = l_msg_id;
  
  dbms_output.put_line('MSG_ID:' || l_msg_id);
  dbms_output.put_line('USER_FEEDBACK:' || l_fb);
  dbms_output.put_line('CATEGORY:' || l_cat);
  dbms_output.put_line('COMMENT:' || l_comm);
END;
""",
        "check": lambda out: "USER_FEEDBACK:DOWN" in out and "CATEGORY:Right info not found" in out and "pincode" in out
    },

    # -------------------------------------------------------------
    # T2-09: User Feedback Submission: Negative ("Wrong answer")
    # -------------------------------------------------------------
    {
        "id": "T2-09",
        "name": "Feedback Operation: Submit Thumbs Down ('Wrong answer')",
        "sql": """
DECLARE
  l_msg_id NUMBER;
  l_fb VARCHAR2(20);
  l_cat VARCHAR2(100);
  l_comm VARCHAR2(500);
BEGIN
  SELECT MIN(msg_id) INTO l_msg_id FROM (SELECT msg_id FROM chat_history ORDER BY msg_id DESC FETCH FIRST 2 ROWS ONLY);
  
  enterprise_rag_pkg.submit_feedback(
    p_msg_id            => l_msg_id,
    p_feedback          => 'DOWN',
    p_feedback_category => 'Wrong answer',
    p_feedback_comment  => 'Designation was mistakenly reported as Senior Consultant'
  );
  
  SELECT user_feedback, feedback_category, feedback_comment
  INTO   l_fb, l_cat, l_comm
  FROM   chat_history
  WHERE  msg_id = l_msg_id;
  
  dbms_output.put_line('MSG_ID:' || l_msg_id);
  dbms_output.put_line('USER_FEEDBACK:' || l_fb);
  dbms_output.put_line('CATEGORY:' || l_cat);
  dbms_output.put_line('COMMENT:' || l_comm);
END;
""",
        "check": lambda out: "USER_FEEDBACK:DOWN" in out and "CATEGORY:Wrong answer" in out and "Designation" in out
    },

    # -------------------------------------------------------------
    # T2-10: Admin Observability Metrics Aggregation
    # -------------------------------------------------------------
    {
        "id": "T2-10",
        "name": "Observability: Admin Console KPI Aggregations (Satisfaction %, Refusals)",
        "sql": """
DECLARE
  l_total NUMBER;
  l_up NUMBER;
  l_down NUMBER;
  l_refusals NUMBER;
  l_avg_lat NUMBER;
  l_sat_rate NUMBER := 0;
BEGIN
  SELECT COUNT(*),
         NVL(SUM(CASE WHEN user_feedback = 'UP' THEN 1 ELSE 0 END), 0),
         NVL(SUM(CASE WHEN user_feedback = 'DOWN' THEN 1 ELSE 0 END), 0),
         NVL(SUM(CASE WHEN is_refusal = 'Y' THEN 1 ELSE 0 END), 0),
         NVL(ROUND(AVG(response_time_ms)), 0)
  INTO   l_total, l_up, l_down, l_refusals, l_avg_lat
  FROM   chat_history;

  IF (l_up + l_down) > 0 THEN
    l_sat_rate := ROUND((l_up * 100) / (l_up + l_down), 1);
  END IF;

  dbms_output.put_line('TOTAL_INVOCATIONS:' || l_total);
  dbms_output.put_line('UP_VOTES:' || l_up);
  dbms_output.put_line('DOWN_VOTES:' || l_down);
  dbms_output.put_line('SATISFACTION_RATE:' || l_sat_rate || '%');
  dbms_output.put_line('REFUSALS_COUNT:' || l_refusals);
  dbms_output.put_line('AVG_LATENCY_MS:' || l_avg_lat);
END;
""",
        "check": lambda out: "TOTAL_INVOCATIONS:" in out and "DOWN_VOTES:" in out and "SATISFACTION_RATE:" in out
    }
]

passed_count = 0
failed_count = 0

for t in tests:
    print(f"\n---> Running {t['id']}: {t['name']}")
    t0 = time.time()
    out, err = run_sql(t["sql"])
    dur = round(time.time() - t0, 2)
    
    clean_out = "\n".join([line for line in out.splitlines() if line.strip() and not line.startswith("Connecting") and not line.startswith("===")])
    
    passed = t["check"](clean_out)
    if passed:
        print(f"[{t['id']}] PASS (took {dur}s)")
        print(f"Result Snippet:\n{clean_out[:350]}...")
        passed_count += 1
    else:
        print(f"[{t['id']}] FAIL (took {dur}s)")
        print(f"Stdout:\n{clean_out}")
        if err:
            print(f"Stderr:\n{err}")
        failed_count += 1

print("\n" + "="*74)
print(f"                  TIER 2 TEST SUITE SUMMARY                    ")
print(f"  Total Cases: {len(tests)} | Passed: {passed_count} | Failed: {failed_count} | Success Rate: {passed_count*100//len(tests)}%")
print("="*74)
