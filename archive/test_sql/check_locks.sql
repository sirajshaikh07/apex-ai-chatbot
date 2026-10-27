set linesize 120
SELECT b.session_id, b.oracle_username, a.object_name
FROM all_objects a, v$locked_object b
WHERE a.object_id = b.object_id;
exit;
