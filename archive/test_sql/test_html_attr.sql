set serveroutput on
BEGIN
  dbms_output.put_line('Result: [' || apex_escape.html_attribute('YOGI') || ']');
END;
/
exit;
