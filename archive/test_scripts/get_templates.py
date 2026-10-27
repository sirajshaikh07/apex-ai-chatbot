import subprocess

sql_input = """set pagesize 100 linesize 200 feedback off
SELECT template_name, internal_name 
FROM apex_application_temp_region 
WHERE application_id = 101
ORDER BY template_name;
exit;
"""

with open("/home/ubuntu/docs/get_temps.sql", "w") as f:
    f.write(sql_input)

cmd = ["python3", "/home/ubuntu/docs/run_sql.py", "get_temps.sql"]
p = subprocess.run(cmd, capture_output=True, text=True)
print("=== TEMPLATES ===")
print(p.stdout)
