#!/usr/bin/env bash
set -euo pipefail

source /home/ubuntu/project/values.env
source /home/ubuntu/.secrets.env

echo "=== Testing APEX_AI.GENERATE via PL/SQL ==="

/usr/local/bin/sql -thin -S /nolog <<EOF
connect AIDEMO/"${AIDEMO_PWD}"@//${VM1_IP}:${DB_PORT}/${DB_SERVICE}
set serveroutput on heading on feedback off linesize 200

DECLARE
  l_app_id   NUMBER;
  l_response CLOB;
  l_t0       TIMESTAMP := systimestamp;
BEGIN
  -- Get existing application id in workspace AIDEMO
  SELECT application_id INTO l_app_id 
  FROM apex_applications 
  WHERE workspace = 'AIDEMO' 
  FETCH FIRST 1 ROWS ONLY;

  -- Create an APEX session
  apex_session.create_session (
    p_app_id   => l_app_id,
    p_page_id  => 1,
    p_username => 'AIDEMO_ADMIN'
  );

  -- Call APEX_AI.GENERATE using our configured local_ollama service
  l_response := apex_ai.generate (
    p_service_static_id => 'local_ollama',
    p_prompt            => 'Reply with the single word OK'
  );

  dbms_output.put_line('----------------------------------------');
  dbms_output.put_line('APEX_AI Response: ' || l_response);
  dbms_output.put_line('Elapsed time: ' || round(extract(second from (systimestamp - l_t0)), 2) || ' seconds');
  dbms_output.put_line('----------------------------------------');
END;
/
exit;
EOF

echo "=== APEX_AI Test Complete! ==="
