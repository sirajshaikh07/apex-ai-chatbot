#!/usr/bin/env bash
set -euo pipefail

echo "=============================================="
echo "  Phase 8: Database Network ACL & API Bridge"
echo "=============================================="

source /home/ubuntu/project/values.env
source /home/ubuntu/.secrets.env

mkdir -p /home/ubuntu/project/sql

echo "[1] Granting DBMS_NETWORK_ACL_ADMIN to APEX_260200 and AIDEMO for VM2:11434..."
/usr/local/bin/sql -thin -S /nolog <<EOF
connect sys/"${SYS_PWD}"@//${VM1_IP}:${DB_PORT}/${DB_SERVICE} as sysdba
set serveroutput on heading on feedback off linesize 200

BEGIN
  -- Grant connect privilege to APEX internal engine schema (APEX_260200)
  DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
    host           => '${VM2_IP}',
    lower_port     => 11434,
    upper_port     => 11434,
    ace            => xs\$ace_type(
                        privilege_list => xs\$name_list('connect'),
                        principal_name => '${APEX_INTERNAL_SCHEMA}',
                        principal_type => xs_acl.ptype_db
                      )
  );

  -- Grant connect privilege to AIDEMO schema
  DBMS_NETWORK_ACL_ADMIN.APPEND_HOST_ACE(
    host           => '${VM2_IP}',
    lower_port     => 11434,
    upper_port     => 11434,
    ace            => xs\$ace_type(
                        privilege_list => xs\$name_list('connect'),
                        principal_name => 'AIDEMO',
                        principal_type => xs_acl.ptype_db
                      )
  );
  COMMIT;
  dbms_output.put_line('Network ACL appended successfully for host ${VM2_IP}:11434');
END;
/

PROMPT --- Verifying DBA_HOST_ACES for ${VM2_IP} ---
SELECT host, lower_port, upper_port, ace_order, principal, privilege, grant_type
FROM dba_host_aces
WHERE host = '${VM2_IP}';
exit;
EOF

echo ""
echo "[2] Testing Database-to-LLM HTTP Call via UTL_HTTP as AIDEMO..."
/usr/local/bin/sql -thin -S /nolog <<EOF
connect AIDEMO/"${AIDEMO_PWD}"@//${VM1_IP}:${DB_PORT}/${DB_SERVICE}
set heading on feedback off pagesize 100 linesize 200

PROMPT --- Calling Ollama API from inside Oracle Database ---
SELECT utl_http.request('http://${VM2_IP}:11434/api/tags') as ollama_api_response FROM dual;
exit;
EOF

# Copy script to ~/project/sql/08_acl.sql
cp /home/ubuntu/docs/08_acl.sh /home/ubuntu/project/sql/08_acl.sh

echo ""
echo "=== Phase 8 ACL & Cross-VM API Bridge Verified! ==="
