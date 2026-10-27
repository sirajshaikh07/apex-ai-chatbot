set serveroutput on size unlimited feedback off linesize 120 pagesize 0 trimout on
DECLARE
  v_offset NUMBER;
  v_len NUMBER;
  v_piece VARCHAR2(100);
BEGIN
  FOR r IN (SELECT chunk_no, chunk_text FROM doc_chunks WHERE doc_id = 85 ORDER BY chunk_no) LOOP
    dbms_output.put_line('=== CHUNK ' || r.chunk_no || ' ===');
    v_len := LENGTH(r.chunk_text);
    v_offset := 1;
    WHILE v_offset <= v_len LOOP
      v_piece := SUBSTR(r.chunk_text, v_offset, 100);
      dbms_output.put_line(v_piece);
      v_offset := v_offset + 100;
    END LOOP;
  END LOOP;
END;
/
exit;
