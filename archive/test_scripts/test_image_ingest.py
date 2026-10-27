import subprocess

with open('/home/ubuntu/docs/sample_scan.png', 'rb') as f:
    hex_str = f.read().hex().upper()

sql = f"""set serveroutput on size unlimited feedback off linesize 200 pagesize 0 trimout on
DECLARE
  l_raw RAW(32767) := '{hex_str}';
  l_blob BLOB;
  l_chunks NUMBER;
BEGIN
  DELETE FROM apex_application_temp_files WHERE name = 'TEMP_SAMPLE_SCAN_PNG';
  
  INSERT INTO apex_application_temp_files (name, filename, mime_type, blob_content)
  VALUES ('TEMP_SAMPLE_SCAN_PNG', 'sample_scan.png', 'image/png', l_raw);
  
  COMMIT;
  
  -- Run the upgraded ingestion procedure with OCR fallback
  ingest_file_document(
    p_file_name    => 'TEMP_SAMPLE_SCAN_PNG',
    p_title        => 'sample_scan.png',
    p_chunks_count => l_chunks
  );
  
  dbms_output.put_line('SUCCESSFULLY INGESTED SCANNED IMAGE!');
  dbms_output.put_line('CHUNKS CREATED: ' || l_chunks);
  
  FOR c IN (SELECT doc_id, chunk_no, DBMS_LOB.SUBSTR(chunk_text, 200, 1) as txt FROM doc_chunks WHERE doc_id = (SELECT doc_id FROM source_docs WHERE title = 'sample_scan.png')) LOOP
    dbms_output.put_line('CHUNK ' || c.chunk_no || ': ' || c.txt);
  END LOOP;
END;
/
exit;
"""

with open('/home/ubuntu/docs/run_test_image_ingest.sql', 'w') as f:
    f.write(sql)

p = subprocess.run(["python3", "/home/ubuntu/docs/run_sql.py", "run_test_image_ingest.sql"], capture_output=True, text=True, timeout=60)
print(p.stdout)
if p.stderr:
    print("STDERR:", p.stderr)
