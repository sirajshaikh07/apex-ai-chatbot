set serveroutput on linesize 200 pagesize 100 long 50000
SELECT attribute_01
FROM apex_application_authorization
WHERE application_id = 101;
exit;
