set serveroutput on size unlimited feedback off linesize 200 pagesize 0 trimout on
DECLARE
  l_blob BLOB;
  l_resp CLOB;
BEGIN
  l_blob := utl_raw.cast_to_raw('Candidate Bio-Data: Safa Himmatkha Pathan' || chr(10) || 'Education: 12th Commerce');
  
  apex_web_service.set_request_headers(
    p_name_01  => 'Content-Type',
    p_value_01 => 'text/plain'
  );

  l_resp := apex_web_service.make_rest_request(
    p_url         => 'http://20.0.1.39:5055/ocr?filename=test.txt',
    p_http_method => 'POST',
    p_body_blob   => l_blob
  );

  dbms_output.put_line('OCR RESPONSE: ' || l_resp);
EXCEPTION
  WHEN OTHERS THEN
    dbms_output.put_line('ERR: ' || SQLERRM);
END;
/
exit;
