import subprocess

sql_test = """set serveroutput on size unlimited feedback off linesize 200 pagesize 0 trimout on
DECLARE
  l_ans CLOB;
  l_src VARCHAR2(1000);
  l_sess NUMBER := 999111;

  PROCEDURE ask_q(p_q VARCHAR2) IS
  BEGIN
    dbms_output.put_line('====================================================');
    dbms_output.put_line('QUESTION: ' || p_q);
    dbms_output.put_line('====================================================');
    enterprise_rag_pkg.ask_with_context(
      p_question   => p_q,
      p_session_id => l_sess,
      p_user_name  => 'TEST_USER',
      p_answer     => l_ans,
      p_sources    => l_src
    );
    dbms_output.put_line('SOURCES: ' || NVL(l_src, 'NONE'));
    dbms_output.put_line('ANSWER:');
    dbms_output.put_line(l_ans);
    
    INSERT INTO chat_history (session_id, user_name, user_prompt, ai_response, sources)
    VALUES (l_sess, 'TEST_USER', p_q, l_ans, l_src);
    COMMIT;
  END;

BEGIN
  -- Test 1: Identify Person from uploaded bio_data.txt
  ask_q('Who is Safa Himmatkha Pathan?');

  -- Test 2: Multi-turn pronoun question
  ask_q('What is her age, education, and address?');

  -- Test 3: Contact details extraction
  ask_q('What is the contact number?');

  -- Test 4: Stale / ungrounded entity test (Siraj / PSPCL)
  ask_q('Who is Siraj in PSPCL?');

  -- Clean up test session
  DELETE FROM chat_history WHERE session_id = l_sess;
  COMMIT;
END;
/
exit;
"""

with open("/home/ubuntu/docs/test_rag_direct.sql", "w") as f:
    f.write(sql_test)

cmd = ["python3", "/home/ubuntu/docs/run_sql.py", "test_rag_direct.sql"]
p = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
print(p.stdout)
if p.stderr:
    print("STDERR:", p.stderr)
