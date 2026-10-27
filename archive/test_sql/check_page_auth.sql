set serveroutput on linesize 200
SELECT page_id, page_name, authorization_scheme, authorization_scheme_id
FROM apex_application_pages
WHERE application_id = 101 AND page_id = 2;
exit;
