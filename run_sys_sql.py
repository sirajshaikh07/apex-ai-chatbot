import os
import subprocess
import sys

def main():
    sql_file = sys.argv[1] if len(sys.argv) > 1 else "check_admin.sql"
    env = os.environ.copy()
    
    pwd = "Apex_26ai_2026Free"
    ip = "20.0.1.130"
    port = "1521"
    service = "FREEPDB1"

    conn_str = f'sys/{pwd}@//{ip}:{port}/{service} as sysdba'
    print(f"Connecting to {ip}:{port}/{service} as SYSDBA...")

    cmd = ["/usr/local/bin/sql", "-S", "-thin", conn_str, f"@{sql_file}"]
    p = subprocess.run(cmd, capture_output=True, text=True, env=env, stdin=subprocess.DEVNULL)

    print("=== STDOUT ===")
    print(p.stdout)
    if p.stderr:
        print("=== STDERR ===")
        print(p.stderr)

if __name__ == "__main__":
    main()
