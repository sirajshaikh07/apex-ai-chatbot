import os
import subprocess

sql_input = """set serveroutput on
DECLARE
  l_ans CLOB;
  l_src VARCHAR2(1000);
BEGIN
  policy_rag_pkg.ask_with_sources(
    p_question => 'Hii',
    p_answer   => l_ans,
    p_sources  => l_src
  );
  dbms_output.put_line('=== TEST: Hii ===');
  dbms_output.put_line('Sources: [' || l_src || ']');
  dbms_output.put_line('Answer:' || CHR(10) || l_ans);
END;
/

DECLARE
  l_ans CLOB;
  l_src VARCHAR2(1000);
BEGIN
  policy_rag_pkg.ask_with_sources(
    p_question => 'What is the guaranteed response time for a Severity 1 Critical Outage?',
    p_answer   => l_ans,
    p_sources  => l_src
  );
  dbms_output.put_line('=== TEST: Severity 1 ===');
  dbms_output.put_line('Sources: [' || l_src || ']');
  dbms_output.put_line('Answer:' || CHR(10) || l_ans);
END;
/
exit;
"""

with open("/home/ubuntu/docs/test_query.sql", "w") as f:
    f.write(sql_input)

cmd = ["python3", "/home/ubuntu/docs/run_sql.py", "test_query.sql"]
p = subprocess.run(cmd, capture_output=True, text=True)
with open("/home/ubuntu/docs/test_query.log", "w") as f:
    f.write(p.stdout)
    if p.stderr:
        f.write("\nSTDERR:\n" + p.stderr)
print("Done running test_greeting.py")
