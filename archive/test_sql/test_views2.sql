set serveroutput on
BEGIN
  FOR r IN (SELECT view_name FROM all_views WHERE view_name LIKE '%APEX%USER%') LOOP
    dbms_output.put_line(r.view_name);
  END LOOP;
END;
/
exit;
