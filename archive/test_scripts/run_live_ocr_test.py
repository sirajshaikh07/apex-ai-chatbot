import subprocess

with open('/home/ubuntu/docs/sample_scan.png', 'rb') as f:
    hex_str = f.read().hex().upper()

sql = f"""set serveroutput on size unlimited feedback off linesize 200 pagesize 0 trimout on
DECLARE
  l_raw RAW(32767) := '{hex_str}';
  l_blob BLOB;
  l_chunks NUMBER;
  l_ans CLOB;
  l_src VARCHAR2(500);
BEGIN
  DBMS_LOB.CREATETEMPORARY(l_blob, TRUE);
  DBMS_LOB.WRITEAPPEND(l_blob, UTL_RAW.LENGTH(l_raw), l_raw);
  
  dbms_output.put_line('=== 1. INGESTING SCANNED IMAGE VIA INGEST_DOCUMENT_BLOB ===');
  ingest_document_blob(
    p_filename     => 'sample_scan.png',
    p_blob         => l_blob,
    p_mime         => 'image/png',
    p_title        => 'sample_scan.png',
    p_chunks_count => l_chunks
  );
  
  dbms_output.put_line('STATUS: SUCCESS!');
  dbms_output.put_line('CHUNKS CREATED: ' || l_chunks);
  
  FOR c IN (SELECT chunk_no, DBMS_LOB.SUBSTR(chunk_text, 300, 1) as txt 
            FROM doc_chunks 
            WHERE doc_id = (SELECT doc_id FROM source_docs WHERE title = 'sample_scan.png')) LOOP
    dbms_output.put_line('CHUNK ' || c.chunk_no || ': ' || c.txt);
  END LOOP;
  
  dbms_output.put_line('=== 2. QUERYING RAG PIPELINE ON SCANNED IMAGE ===');
  enterprise_rag_pkg.ask_with_context(
    p_question   => 'What mobile number and address is on the scanned bio data?',
    p_session_id => 55555,
    p_user_name  => 'OCR_TESTER',
    p_answer     => l_ans,
    p_sources    => l_src
  );
  
  dbms_output.put_line('SOURCES: ' || NVL(l_src, 'NONE'));
  dbms_output.put_line('ANSWER:');
  dbms_output.put_line(l_ans);
  
  -- Clean up test scanned image document
  FOR d IN (SELECT doc_id FROM source_docs WHERE title = 'sample_scan.png') LOOP
    delete_document(d.doc_id);
  END LOOP;
  COMMIT;
END;
/
exit;
"""

with open('/home/ubuntu/docs/test_ocr_live.sql', 'w') as f:
    f.write(sql)

p = subprocess.run(["python3", "/home/ubuntu/docs/run_sql.py", "test_ocr_live.sql"], capture_output=True, text=True, timeout=90)
print(p.stdout)
if p.stderr:
    print("STDERR:", p.stderr)
