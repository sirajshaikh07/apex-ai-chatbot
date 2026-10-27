set serveroutput on
BEGIN
  FOR r IN (
    SELECT column_name 
    FROM all_tab_columns 
    WHERE table_name = 'APEX_APPLICATION_PAGE_ITEMS' 
      AND (column_name LIKE '%FILE%' OR column_name LIKE '%BLOB%' OR column_name LIKE '%STORAGE%')
  ) LOOP
    dbms_output.put_line(r.column_name);
  END LOOP;
END;
/
exit;
