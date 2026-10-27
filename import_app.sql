set serveroutput on linesize 200 heading on feedback on
PROMPT === Validating Application ===
apex validate -input /home/ubuntu/project/apps/chatapp

PROMPT === Importing Application into Workspace AIDEMO ===
apex import -input /home/ubuntu/project/apps/chatapp

PROMPT === Verifying Installed Application & Pages ===
SELECT application_id, application_name, alias, workspace 
FROM apex_applications 
WHERE application_id = 101;

SELECT page_id, page_name, page_title 
FROM apex_application_pages 
WHERE application_id = 101 
ORDER BY page_id;

exit;
