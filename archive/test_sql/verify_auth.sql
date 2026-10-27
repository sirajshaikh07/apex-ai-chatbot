set serveroutput on linesize 200
SELECT authorization_scheme_name, scheme_type, attribute_01
FROM apex_application_authorization
WHERE application_id = 101;
exit;
