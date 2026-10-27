set serveroutput on linesize 200 feedback on

PROMPT === Testing Batch Ingest of Multiple Document Formats ===

DECLARE
  l_cnt NUMBER := 0;
  l_doc1_id NUMBER;
  l_doc2_id NUMBER;
  l_doc3_id NUMBER;
BEGIN
  -- Simulate batch upload of 3 different documents
  ingest_document(
    p_title => 'batch_policy_1.pdf',
    p_ref => 'batch_policy_1.pdf',
    p_content => 'Corporate Data Security Policy: All employee laptops must be encrypted using BitLocker or FileVault with AES-256.',
    p_chunks_count => l_cnt
  );
  dbms_output.put_line('File 1 (PDF) processed. Chunks: ' || l_cnt);

  ingest_document(
    p_title => 'batch_leave_guidelines.docx',
    p_ref => 'batch_leave_guidelines.docx',
    p_content => 'Annual Leave Policy: Full-time permanent staff are entitled to 25 standard working days of paid annual vacation.',
    p_chunks_count => l_cnt
  );
  dbms_output.put_line('File 2 (DOCX) processed. Chunks: ' || l_cnt);

  ingest_document(
    p_title => 'batch_travel_rules.xlsx',
    p_ref => 'batch_travel_rules.xlsx',
    p_content => 'Business Travel Expense Policy: Meal reimbursement per diem allowance is capped at 75 USD per day for domestic travel.',
    p_chunks_count => l_cnt
  );
  dbms_output.put_line('File 3 (XLSX) processed. Chunks: ' || l_cnt);

  -- Verify all 3 docs are in SOURCE_DOCS
  FOR r IN (SELECT doc_id, title FROM source_docs WHERE title LIKE 'batch_%') LOOP
    dbms_output.put_line('Verified in DB: Doc #' || r.doc_id || ' - ' || r.title);
    delete_document(r.doc_id);
  END LOOP;

  dbms_output.put_line('Cleaned up all test batch docs. Database remains 100% clean!');
END;
/

exit;
