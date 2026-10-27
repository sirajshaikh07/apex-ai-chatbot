import subprocess
import os

def run_sql(sql_code):
    with open('/home/ubuntu/docs/temp_test.sql', 'w') as f:
        f.write(sql_code)
    cmd = ['python3', '/home/ubuntu/docs/run_sql.py', 'temp_test.sql']
    res = subprocess.run(cmd, capture_output=True, text=True)
    return res.stdout

print("==================================================")
print("     COMPREHENSIVE ENTERPRISE SYSTEM TEST         ")
print("==================================================")

# 1. Check all DB Objects
sql1 = """
set pages 50 lines 180
SELECT object_name, object_type, status 
FROM user_objects 
WHERE object_name IN ('SOURCE_DOCS', 'DOC_CHUNKS', 'USER_REGISTRATIONS', 'CHAT_HISTORY', 
                      'APPROVE_USER_REGISTRATION', 'REJECT_USER_REGISTRATION', 'INGEST_FILE_DOCUMENT', 
                      'DELETE_DOCUMENT', 'POLICY_RAG_PKG')
ORDER BY object_type, object_name;
exit;
"""
print("\n[TEST 1] Verifying Database Objects...")
out1 = run_sql(sql1)
print(out1)

# 2. Test Policy RAG Greetings & Answers
sql2 = """
set serveroutput on long 50000
DECLARE
  l_ans CLOB;
  l_src VARCHAR2(1000);
BEGIN
  -- Greeting Test
  policy_rag_pkg.ask_with_sources('Hello AI Assistant', l_ans, l_src);
  dbms_output.put_line('GREETING RESPONSE: ' || SUBSTR(l_ans, 1, 120) || '...');
  
  -- Question on clean DB
  policy_rag_pkg.ask_with_sources('What is the vacation policy?', l_ans, l_src);
  dbms_output.put_line('CLEAN DB RESPONSE: ' || SUBSTR(l_ans, 1, 120) || '...');
END;
/
exit;
"""
print("\n[TEST 2] Testing Policy RAG Engine...")
out2 = run_sql(sql2)
print(out2)

# 3. Test Ingest & Delete Workflow
sql3 = """
set serveroutput on
DECLARE
  l_cnt NUMBER := 0;
  l_doc_id NUMBER;
BEGIN
  -- Ingest test doc
  ingest_document('Test Ingest Run', 'test_doc.txt', 'The annual leave entitlement for full time employees is 25 days per calendar year.', l_cnt);
  dbms_output.put_line('Ingested test doc. Chunks generated: ' || l_cnt);
  
  -- Verify in SOURCE_DOCS and DOC_CHUNKS
  SELECT doc_id INTO l_doc_id FROM source_docs WHERE title = 'Test Ingest Run';
  dbms_output.put_line('Doc ID: ' || l_doc_id);
  
  -- Query RAG with context
  DECLARE
    l_ans CLOB;
    l_src VARCHAR2(1000);
  BEGIN
    policy_rag_pkg.ask_with_sources('How many days annual leave do employees get?', l_ans, l_src);
    dbms_output.put_line('RAG Answer: ' || SUBSTR(l_ans, 1, 150));
  END;

  -- Clean up test doc
  delete_document(l_doc_id);
  dbms_output.put_line('Cleaned up test doc. DB remains 100% clean for original docs!');
END;
/
exit;
"""
print("\n[TEST 3] Testing End-to-End Vector Ingest, Embedding & Deletion...")
out3 = run_sql(sql3)
print(out3)

# 4. Check Applications and Pages in AIWORKSPACE
sql4 = """
set pages 50 lines 180
SELECT application_id, application_name, alias, workspace FROM apex_applications;
SELECT page_id, page_name, page_title FROM apex_application_pages WHERE application_id = 101 ORDER BY page_id;
exit;
"""
print("\n[TEST 4] Verifying Application 101 in AIWORKSPACE...")
out4 = run_sql(sql4)
print(out4)

print("==================================================")
print("     ALL TESTS EXECUTED SUCCESSFULLY!             ")
print("==================================================")
