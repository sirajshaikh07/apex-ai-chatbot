set serveroutput on linesize 120
SELECT request_id, username, full_name, email, status FROM user_registrations;
exit;
