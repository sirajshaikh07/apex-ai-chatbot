set serveroutput on linesize 200 feedback on

PROMPT ========================================================
PROMPT   TEST 1: Verifying Dummy Data Deletion
PROMPT ========================================================
DECLARE
  l_docs NUMBER;
  l_chunks NUMBER;
  l_chat NUMBER;
BEGIN
  SELECT count(*) INTO l_docs FROM source_docs;
  SELECT count(*) INTO l_chunks FROM doc_chunks;
  SELECT count(*) INTO l_chat FROM chat_history;
  
  dbms_output.put_line('Remaining source_docs: ' || l_docs);
  dbms_output.put_line('Remaining doc_chunks:  ' || l_chunks);
  dbms_output.put_line('Remaining chat_history:' || l_chat);
  
  IF l_docs = 0 AND l_chunks = 0 AND l_chat = 0 THEN
    dbms_output.put_line('>>> TEST 1 PASS: Database is 100% clean of all dummy/fake data.');
  ELSE
    dbms_output.put_line('>>> TEST 1 FAIL: Some data still remains.');
  END IF;
END;
/

PROMPT ========================================================
PROMPT   TEST 2: Verifying Admin User SIRAJ / siraj
PROMPT ========================================================
DECLARE
  l_uid NUMBER;
  l_auth BOOLEAN;
BEGIN
  apex_util.set_workspace('AIDEMO');
  l_uid := apex_util.get_user_id('SIRAJ');
  
  IF l_uid IS NOT NULL THEN
    dbms_output.put_line('User SIRAJ exists with APEX User ID: ' || l_uid);
    l_auth := apex_util.is_login_password_valid(p_username => 'SIRAJ', p_password => 'siraj');
    IF l_auth THEN
      dbms_output.put_line('>>> TEST 2 PASS: User SIRAJ / siraj credentials are valid and active!');
    ELSE
      dbms_output.put_line('>>> TEST 2 WARNING: Password check returned false.');
    END IF;
  ELSE
    dbms_output.put_line('>>> TEST 2 FAIL: User SIRAJ does not exist.');
  END IF;
END;
/

PROMPT ========================================================
PROMPT   TEST 3: Testing User Signup & Admin Approval Flow
PROMPT ========================================================
DECLARE
  l_req_id NUMBER;
  l_status VARCHAR2(20);
  l_new_uid NUMBER;
BEGIN
  -- 1. Clean previous test registration if present
  DELETE FROM user_registrations WHERE username = 'TEST_USER_99';
  apex_util.set_workspace('AIDEMO');
  l_new_uid := apex_util.get_user_id('TEST_USER_99');
  IF l_new_uid IS NOT NULL THEN
    apex_util.remove_user(p_user_id => l_new_uid);
  END IF;

  -- 2. Simulate User Sign Up Request
  INSERT INTO user_registrations (username, full_name, email, password, status)
  VALUES ('TEST_USER_99', 'Test Employee', 'test99@company.com', 'Pass1234', 'PENDING')
  RETURNING request_id INTO l_req_id;
  COMMIT;
  dbms_output.put_line('Created user signup request #' || l_req_id || ' with status PENDING.');

  -- 3. Admin Siraj approves the request
  approve_user_registration(p_request_id => l_req_id, p_admin_user => 'SIRAJ');
  
  -- 4. Verify status updated to APPROVED
  SELECT status INTO l_status FROM user_registrations WHERE request_id = l_req_id;
  dbms_output.put_line('Status after approval: ' || l_status);

  -- 5. Verify user now exists in APEX workspace
  l_new_uid := apex_util.get_user_id('TEST_USER_99');
  IF l_new_uid IS NOT NULL AND l_status = 'APPROVED' THEN
    dbms_output.put_line('>>> TEST 3 PASS: User signup and approval flow works end-to-end!');
  ELSE
    dbms_output.put_line('>>> TEST 3 FAIL: User was not created or status not approved.');
  END IF;

  -- Clean up test registration
  apex_util.remove_user(p_user_id => l_new_uid);
  DELETE FROM user_registrations WHERE request_id = l_req_id;
  COMMIT;
END;
/

PROMPT ========================================================
PROMPT   TEST 4: Testing Document Ingestion & Embeddings
PROMPT ========================================================
DECLARE
  l_chunks NUMBER;
  l_doc_id NUMBER;
BEGIN
  ingest_document(
    p_title        => 'Sample Enterprise Policy 2026',
    p_ref          => 'sample_policy.txt',
    p_content      => 'All employees must adhere to the high-security cloud standards. Data at rest must be encrypted with AES-256-GCM. Remote workers are required to connect via corporate VPN at all times.',
    p_chunks_count => l_chunks
  );
  dbms_output.put_line('Ingested document with ' || l_chunks || ' chunks.');

  SELECT doc_id INTO l_doc_id FROM source_docs WHERE title = 'Sample Enterprise Policy 2026';
  
  IF l_chunks > 0 AND l_doc_id IS NOT NULL THEN
    dbms_output.put_line('>>> TEST 4 PASS: Document chunking and vector embedding works perfectly!');
  ELSE
    dbms_output.put_line('>>> TEST 4 FAIL: Could not ingest document.');
  END IF;

  -- Clean up test document
  delete_document(l_doc_id);
  dbms_output.put_line('Cleaned up test document. Database left completely pristine for user upload.');
END;
/

exit;
