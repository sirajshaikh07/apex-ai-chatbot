set serveroutput on size unlimited feedback off linesize 200 pagesize 0 trimout on
DECLARE
  v_clob CLOB;
BEGIN
  SELECT chunk_text INTO v_clob FROM doc_chunks WHERE doc_id = 103;
  dbms_output.put_line('LENGTH: ' || LENGTH(v_clob));
  dbms_output.put_line('TEXT:');
  dbms_output.put_line(DBMS_LOB.SUBSTR(v_clob, 1000, 1));
  IF LENGTH(v_clob) > 1000 THEN
    dbms_output.put_line(DBMS_LOB.SUBSTR(v_clob, 1000, 1001));
  END IF;
END;
/
exit;
