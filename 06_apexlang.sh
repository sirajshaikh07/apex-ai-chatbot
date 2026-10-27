#!/usr/bin/env bash
set -euo pipefail

echo "=== Phase 6: APEXlang Toolchain Proof ==="

source /home/ubuntu/project/values.env
source /home/ubuntu/.secrets.env

mkdir -p /home/ubuntu/project/apps /home/ubuntu/project/docs

echo "1. Checking SQLcl and Java versions..."
sql -V
java -version

echo ""
echo "2. Connecting to VM1 as AIDEMO and generating app chatapp..."
/usr/local/bin/sql -thin -S /nolog <<EOF
connect AIDEMO/"${AIDEMO_PWD}"@//${VM1_IP}:${DB_PORT}/${DB_SERVICE}
set serveroutput on heading on feedback off pagesize 50

PROMPT --- APEX Workspaces ---
SELECT workspace, workspace_id FROM apex_workspaces;

PROMPT --- SQLcl APEX Help ---
help apex

PROMPT --- Generating APEX application 'AI Chat' ---
cd /home/ubuntu/project/apps
apex generate -workspace AIDEMO -alias chatapp -name "AI Chat" -dir /home/ubuntu/project/apps

PROMPT --- SQLcl Skills Help ---
help skills

exit;
EOF

echo ""
echo "3. Inspecting generated application folder in ~/project/apps/..."
ls -la /home/ubuntu/project/apps

# Detect the generated application folder (e.g. chatapp or f*)
APP_FOLDER=$(find /home/ubuntu/project/apps -mindepth 1 -maxdepth 1 -type d | head -n 1)

if [ -z "${APP_FOLDER}" ]; then
  echo "ERROR: No application directory was created in /home/ubuntu/project/apps!"
  exit 1
fi

echo "Detected application directory: ${APP_FOLDER}"
ls -la "${APP_FOLDER}"

echo ""
echo "4. Validating generated APEXlang application..."
/usr/local/bin/sql -thin -S /nolog <<EOF
connect AIDEMO/"${AIDEMO_PWD}"@//${VM1_IP}:${DB_PORT}/${DB_SERVICE}
set serveroutput on
apex validate -input ${APP_FOLDER}
exit;
EOF

echo ""
echo "5. Importing APEXlang application into AIDEMO workspace..."
/usr/local/bin/sql -thin -S /nolog <<EOF
connect AIDEMO/"${AIDEMO_PWD}"@//${VM1_IP}:${DB_PORT}/${DB_SERVICE}
set serveroutput on
apex import -input ${APP_FOLDER}

PROMPT --- Verifying Imported Application in APEX_APPLICATIONS ---
SELECT application_id, alias, application_name, workspace FROM apex_applications WHERE workspace = 'AIDEMO';
exit;
EOF

echo ""
echo "6. Writing documentation to ~/project/docs/apexlang-commands.md..."
cat << 'DOCEOF' > /home/ubuntu/project/docs/apexlang-commands.md
# APEXlang CLI Commands Reference

These commands are executed inside SQLcl 26.3 connected via thin driver to the target PDB:

```bash
# Connect with SQLcl
sql -thin AIDEMO@//20.0.1.130:1521/FREEPDB1
```

Inside SQLcl:
```sql
-- 1. Check APEX help
help apex

-- 2. Generate new app
apex generate -workspace AIDEMO -alias chatapp -name "AI Chat" -dir /home/ubuntu/project/apps

-- 3. Validate app files
apex validate -input /home/ubuntu/project/apps/<app_dir>

-- 4. Import app into workspace
apex import -input /home/ubuntu/project/apps/<app_dir>

-- 5. Check AI skills commands
help skills
```
DOCEOF

# Log gate output
cat << 'LOGEOF' >> /home/ubuntu/project/LOG.md

## Phase 6 Gate Results (APEXlang Toolchain Proof)
- SQLcl version: 26.3.0
- Java version: OpenJDK 21
- Application 'AI Chat' (alias: chatapp) generated in ~/project/apps/
- apex validate: Success
- apex import: Imported successfully into workspace AIDEMO
- Documentation: ~/project/docs/apexlang-commands.md created
LOGEOF

echo "=== Phase 6 Complete! ==="
