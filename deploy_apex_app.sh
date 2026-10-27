#!/usr/bin/env bash
set -euo pipefail

echo "=========================================================="
echo "  Deploying Enterprise AI Chat & Admin App to APEX 101"
echo "=========================================================="

source /home/ubuntu/project/values.env
source /home/ubuntu/.secrets.env

# 1. Sync updated files to project apps folder
echo "[1] Syncing files to /home/ubuntu/project/apps/chatapp/..."
cp -r /home/ubuntu/docs/chatapp/* /home/ubuntu/project/apps/chatapp/

# 2. Validate and Import using SQLcl
echo ""
echo "[2] Validating and Importing APEXlang Application..."
/usr/local/bin/sql -thin AIDEMO/"${AIDEMO_PWD}"@//${VM1_IP}:${DB_PORT}/${DB_SERVICE} << 'EOF'
set serveroutput on linesize 200 heading on feedback on

PROMPT === Validating Application ===
apex validate -input /home/ubuntu/project/apps/chatapp

PROMPT === Importing Application into Workspace AIDEMO ===
apex import -input /home/ubuntu/project/apps/chatapp

PROMPT === Verifying Installed Application & Pages ===
SELECT application_id, application_name, alias, workspace 
FROM apex_applications 
WHERE workspace = 'AIDEMO';

SELECT page_id, page_name, page_title 
FROM apex_application_pages 
WHERE application_id = 101 
ORDER BY page_id;

exit;
EOF

echo ""
echo "=========================================================="
echo "  Application Successfully Deployed to APEX 101!"
echo "  App URL: http://92.4.82.132:8080/ords/r/aidemo/chatapp/"
echo "  Login:   User: AIDEMO_ADMIN | Password: ${WS_ADMIN_PWD}"
echo "=========================================================="
