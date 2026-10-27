import re
import os

def main():
    log_file = "/home/ubuntu/docs/sql_run.log"
    if not os.path.exists(log_file):
        print(f"Log file {log_file} does not exist yet. Please run: python3 run_sql.py inspect_siraj_all_tasks.sql")
        return

    with open(log_file, "r", encoding="utf-8", errors="ignore") as f:
        text = f.read()

    print("=== SEARCHING FOR SIRAJ TASKS IN DATABASE DUMP ===")
    
    # Extract all lines mentioning Siraj
    lines = text.split("\n")
    siraj_lines = [l for l in lines if "siraj" in l.lower()]
    print(f"Total lines mentioning Siraj: {len(siraj_lines)}")

    print("\n--- SAMPLE LINES MENTIONING SIRAJ ---")
    for l in siraj_lines[:25]:
        print(l.strip())

if __name__ == "__main__":
    main()
