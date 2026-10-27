set serveroutput on
DECLARE
  l_cnt NUMBER;
BEGIN
  -- Test APEX_UTIL.CURRENT_USER_IN_GROUP
  dbms_output.put_line('Checking current user: ' || v('APP_USER'));
  
  -- Test if APEX_APPL_USER_ROLES or similar exists
  SELECT count(*) INTO l_cnt FROM all_views WHERE view_name LIKE '%APEX%USER%';
  dbms_output.put_line('Matching views: ' || l_cnt);
END;
/
exit;
