set serveroutput on
DECLARE
  l_name VARCHAR2(100) := 'Yogita';
  l_first VARCHAR2(100);
  l_last VARCHAR2(100);
BEGIN
  BEGIN
    l_first := NVL(SUBSTR(l_name, 1, INSTR(l_name, ' ') - 1), l_name);
    dbms_output.put_line('l_first: ' || l_first);
  EXCEPTION WHEN OTHERS THEN
    dbms_output.put_line('Error in l_first: ' || SQLERRM);
  END;

  BEGIN
    l_last := NVL(SUBSTR(l_name, INSTR(l_name, ' ') + 1), 'User');
    dbms_output.put_line('l_last: ' || l_last);
  EXCEPTION WHEN OTHERS THEN
    dbms_output.put_line('Error in l_last: ' || SQLERRM);
  END;
END;
/
exit;
