set serveroutput on size unlimited feedback off linesize 200 pagesize 0 trimout on
DECLARE
  l_resp CLOB;
BEGIN
  l_resp := utl_http.request('http://20.0.1.39:5055/health');
  dbms_output.put_line('RESP: ' || l_resp);
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('ERR: ' || SQLERRM);
    dbms_output.put_line('TRACE: ' || dbms_utility.format_error_backtrace);
END;
/
exit;
