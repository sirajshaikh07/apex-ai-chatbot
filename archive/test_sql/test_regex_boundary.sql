set define off serveroutput on size unlimited feedback off linesize 200 pagesize 0 trimout on
DECLARE
  l_s VARCHAR2(100) := 'safa ke kitne bhai hain';
  l_out1 VARCHAR2(100);
  l_out2 VARCHAR2(100);
BEGIN
  -- with \b:
  l_out1 := REGEXP_REPLACE(l_s, '\bbhai\b', 'brother');
  -- with (^| )bhai( |$):
  l_out2 := REGEXP_REPLACE(' ' || l_s || ' ', '(^| )bhai( |$)', ' brother ');
  dbms_output.put_line('With \b   : ' || l_out1);
  dbms_output.put_line('With spaces: ' || TRIM(l_out2));
END;
/
exit;
