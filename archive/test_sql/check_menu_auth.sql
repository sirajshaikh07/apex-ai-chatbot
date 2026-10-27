set serveroutput on linesize 220 pagesize 100
SELECT entry_text, entry_target, authorization_scheme
FROM apex_application_list_entries
WHERE application_id = 101 AND list_name = 'Navigation Menu';
exit;
