set serveroutput on linesize 200
DECLARE
  l_app_id NUMBER := 101;
  l_page_id NUMBER := 2;
BEGIN
  apex_session.create_session (
    p_app_id   => l_app_id,
    p_page_id  => l_page_id,
    p_username => 'SIRAJ'
  );
  
  -- Check regions on page 2
  FOR r IN (
    SELECT region_name, source_type, static_id
    FROM apex_application_page_regions
    WHERE application_id = l_app_id AND page_id = l_page_id
    ORDER BY display_sequence
  ) LOOP
    dbms_output.put_line('Region: ' || r.region_name || ' | Type: ' || r.source_type);
  END LOOP;

  apex_session.delete_session;
END;
/
exit;
