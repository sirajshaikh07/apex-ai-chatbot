import os
import shutil
import subprocess

def main():
    print("[1] Syncing /home/ubuntu/docs/chatapp to /home/ubuntu/project/apps/chatapp ...")
    src = "/home/ubuntu/docs/chatapp"
    dst = "/home/ubuntu/project/apps/chatapp"
    if os.path.exists(dst):
        shutil.rmtree(dst)
    shutil.copytree(src, dst)
    print("Files synced successfully.")

    # Prepare SQL script for validate & import
    sql_script = """set serveroutput on linesize 200 heading on feedback on
PROMPT === Validating Application ===
apex validate -input /home/ubuntu/project/apps/chatapp

PROMPT === Importing Application into Workspace AIDEMO ===
apex import -input /home/ubuntu/project/apps/chatapp

PROMPT === Verifying Installed Application & Pages ===
SELECT application_id, application_name, alias, workspace 
FROM apex_applications 
WHERE application_id = 101;

SELECT page_id, page_name, page_title 
FROM apex_application_pages 
WHERE application_id = 101 
ORDER BY page_id;

exit;
"""
    with open("/home/ubuntu/docs/import_app.sql", "w") as f:
        f.write(sql_script)

    print("[2] Running apex validate and apex import via SQLcl...")
    cmd = ["python3", "/home/ubuntu/docs/run_sql.py", "import_app.sql"]
    p = subprocess.run(cmd, capture_output=True, text=True)

    with open("/home/ubuntu/docs/deploy.log", "w") as out:
        out.write(p.stdout)
        if p.stderr:
            out.write("\nSTDERR:\n" + p.stderr)

    print(p.stdout)
    if p.stderr:
        print("STDERR:", p.stderr)

if __name__ == "__main__":
    main()
