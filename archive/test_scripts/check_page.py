import subprocess
import re

# Fetch page 1 HTML using curl with a session or query apex views
sql_input = """set pagesize 0 linesize 32000 long 100000 feedback off
SELECT region_name, static_id, template, template_options 
FROM apex_application_page_regions 
WHERE application_id = 101 AND page_id = 1;
exit;
"""

with open("/home/ubuntu/docs/check_regions.sql", "w") as f:
    f.write(sql_input)

cmd = ["python3", "/home/ubuntu/docs/run_sql.py", "check_regions.sql"]
p = subprocess.run(cmd, capture_output=True, text=True)
print("=== REGIONS ===")
print(p.stdout)
