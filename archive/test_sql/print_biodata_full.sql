set serveroutput on size unlimited feedback off linesize 120 pagesize 0 trimout on
DECLARE
  v_offset NUMBER;
  v_len NUMBER;
  v_piece VARCHAR2(100);
  v_clob CLOB;
BEGIN
  SELECT content INTO v_clob FROM source_docs WHERE doc_id = 103;
  v_len := LENGTH(v_clob);
  v_offset := 1;
  WHILE v_offset <= v_len LOOP
    v_piece := SUBSTR(v_clob, v_offset, 100);
    dbms_output.put_line(v_piece);
    v_offset := v_offset + 100;
  END LOOP;
END;
/
exit;
