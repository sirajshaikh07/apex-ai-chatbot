import subprocess
import sys
import time

tests = [
    ("Q1: Hierarchy", "test_q1_hierarchy.sql"),
    ("Q2: Blocked/Overdue", "test_q2_blocked.sql"),
    ("Q3: Aditya Tasks", "test_q3_aditya.sql"),
    ("Q4: Project Owners", "test_q4_owners.sql"),
    ("Q5: Yogita Tasks", "test_q5_yogita.sql"),
]

print("======================================================================")
print("STARTING RANDOM RAG VERIFICATION SUITE (ONE BY ONE)")
print("======================================================================")

for title, sql_file in tests:
    print(f"\n>>> EXECUTING {title} ({sql_file})...")
    t0 = time.time()
    res = subprocess.run([sys.executable, "run_sql.py", sql_file], capture_output=True, text=True)
    elapsed = time.time() - t0
    print(res.stdout)
    if res.stderr:
        print("STDERR:", res.stderr)
    print(f">>> {title} completed in {elapsed:.1f}s")
    print("----------------------------------------------------------------------")
