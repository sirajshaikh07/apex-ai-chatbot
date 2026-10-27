set serveroutput on
BEGIN
  FOR r IN (SELECT column_name FROM all_tab_columns WHERE table_name = 'APEX_APPL_PLUGIN_ATTRIBUTES' ORDER BY column_id) LOOP
    dbms_output.put_line(r.column_name);
  END LOOP;
END;
/
exit;
