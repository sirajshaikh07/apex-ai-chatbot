set heading on feedback off linesize 200
SELECT application_id, application_name, alias, workspace 
FROM apex_applications 
WHERE workspace = 'AIDEMO';
exit;
