set serveroutput on
BEGIN
  dbms_output.put_line('Result: [' || apex_escape.js_literal('YOGI') || ']');
END;
/
exit;
