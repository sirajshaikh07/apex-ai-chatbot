set serveroutput on
BEGIN
  FOR r IN (
    SELECT column_name 
    FROM all_tab_columns 
    WHERE table_name = 'APEX_APPLICATION_LIST_ENTRIES' 
      AND (column_name LIKE '%AUTH%' OR column_name LIKE '%SEC%')
  ) LOOP
    dbms_output.put_line(r.column_name);
  END LOOP;
END;
/
exit;
