set serveroutput on linesize 200
DECLARE
  l_html CLOB;
  l_cnt NUMBER := 0;
BEGIN
  -- Region 1: user-approvals
  BEGIN
    FOR r IN (
        SELECT request_id, username, full_name, email, 
               TO_CHAR(requested_at, 'YYYY-MM-DD HH24:MI') as req_time,
               status
        FROM user_registrations
        ORDER BY DECODE(status, 'PENDING', 1, 2), request_id DESC
    ) LOOP
        l_cnt := l_cnt + 1;
    END LOOP;
    dbms_output.put_line('Region 1 (user-approvals) executed cleanly. Row count: ' || l_cnt);
  END;

  -- Region 2: kb-overview
  l_cnt := 0;
  BEGIN
    FOR r IN (
        SELECT d.doc_id, d.title, d.source_ref, d.mime_type, d.file_size,
               COUNT(c.chunk_id) as total_chunks,
               TO_CHAR(d.ingested_at, 'YYYY-MM-DD HH24:MI') as vectorized_at
        FROM source_docs d
        LEFT JOIN doc_chunks c ON d.doc_id = c.doc_id
        GROUP BY d.doc_id, d.title, d.source_ref, d.mime_type, d.file_size, d.ingested_at
        ORDER BY d.doc_id DESC
    ) LOOP
        l_cnt := l_cnt + 1;
    END LOOP;
    dbms_output.put_line('Region 2 (kb-overview) executed cleanly. Row count: ' || l_cnt);
  END;
END;
/
exit;
