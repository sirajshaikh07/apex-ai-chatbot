import os
import subprocess
import sys

def main():
    sql_file = sys.argv[1] if len(sys.argv) > 1 else "update_rag_pkg.sql"
    env = os.environ.copy()
    
    # Read secrets if available
    secrets_path = "/home/ubuntu/.secrets.env"
    values_path = "/home/ubuntu/project/values.env"
    for path in [secrets_path, values_path]:
        if os.path.exists(path):
            with open(path) as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith("#") and "=" in line:
                        k, v = line.split("=", 1)
                        v = v.strip("'").strip('"')
                        env[k] = v

    user = "AIDEMO"
    pwd = env.get("AIDEMO_PWD", "Apex_26ai_2026Free")
    ip = env.get("VM1_IP", "20.0.1.130")
    port = env.get("DB_PORT", "1521")
    service = env.get("DB_SERVICE", "FREEPDB1")

    conn_str = f"{user}/{pwd}@//{ip}:{port}/{service}"
    print(f"Connecting to {ip}:{port}/{service} as {user}...")

    timeout_sec = int(env.get("SQL_TIMEOUT", "180"))
    cmd = ["/usr/local/bin/sql", "-S", "-thin", conn_str, f"@{sql_file}"]
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, env=env, stdin=subprocess.DEVNULL, timeout=timeout_sec)
        print("=== STDOUT ===")
        print(p.stdout)
        if p.stderr:
            print("=== STDERR ===")
            print(p.stderr)

        with open("/home/ubuntu/docs/sql_run.log", "w") as out:
            out.write(p.stdout)
            if p.stderr:
                out.write("\nSTDERR:\n" + p.stderr)
    except subprocess.TimeoutExpired as te:
        print(f"ERROR: Command timed out after {timeout_sec}s. Output before timeout: {te.stdout}, stderr: {te.stderr}")

if __name__ == "__main__":
    main()
