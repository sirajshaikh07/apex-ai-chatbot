import subprocess

sql = """set serveroutput on size unlimited feedback off linesize 200 pagesize 0 trimout on
DECLARE
  l_blob BLOB;
  l_chunks NUMBER;
BEGIN
  -- Insert into apex_application_temp_files
  DELETE FROM apex_application_temp_files WHERE filename = 'sample_scan.png';
  
  -- Create empty blob
  INSERT INTO apex_application_temp_files (name, filename, mime_type, blob_content)
  VALUES ('TEMP_SCAN_PNG', 'sample_scan.png', 'image/png', EMPTY_BLOB())
  RETURNING blob_content INTO l_blob;
  
  COMMIT;
END;
/
exit;
"""

with open('load_temp_scan.sql', 'w') as f:
    f.write(sql)
p = subprocess.run(["python3", "run_sql.py", "load_temp_scan.sql"], capture_output=True, text=True)
print(p.stdout)
