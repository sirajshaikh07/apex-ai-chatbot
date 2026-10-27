set serveroutput on feedback off linesize 200
DECLARE
  l_cnt NUMBER;
BEGIN
  FOR r IN (
    SELECT chunk_no, chunk_text
    FROM doc_chunks
    WHERE doc_id = 85
      AND (UPPER(chunk_text) LIKE '%PSPCL%' OR UPPER(chunk_text) LIKE '%SIRAJ%')
    ORDER BY chunk_no
  ) LOOP
    dbms_output.put_line('=== CHUNK ' || r.chunk_no || ' ===');
    dbms_output.put_line(SUBSTR(r.chunk_text, 1, 800));
  END LOOP;
END;
/
exit;
