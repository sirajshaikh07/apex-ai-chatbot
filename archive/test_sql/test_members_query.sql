set heading on feedback off linesize 150 pagesize 50
SELECT project_code, person_name, role_name, total_tasks, done_tasks, open_tasks, substr(details, 1, 80) as details FROM project_members WHERE person_name = 'Siraj' ORDER BY project_code;
exit;
