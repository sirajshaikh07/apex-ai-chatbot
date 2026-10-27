#!/usr/bin/env bash
set -euo pipefail

echo "=== ORDS 26.3 Automated Installation ==="

# Source configuration and secrets
source /home/ubuntu/project/values.env
source /home/ubuntu/.secrets.env

# Confirm APEX is VALID and check existing ORDS users
echo "1. Checking APEX status in FREEPDB1..."
sql -thin -S /nolog <<EOF
connect sys/"${SYS_PWD}"@//${VM1_IP}:${DB_PORT}/${DB_SERVICE} as sysdba
set heading on feedback off pagesize 50
SELECT comp_name, version, status FROM dba_registry WHERE comp_id='APEX';
SELECT username FROM dba_users WHERE username IN ('ORDS_METADATA','ORDS_PUBLIC_USER');
exit;
EOF

# Write passwords securely to temp file for ords install
echo "2. Writing installer secrets to secure ramdisk..."
TEMP_PASS_FILE="/dev/shm/.ords_passwords_$$"
(
  umask 027
  printf "%s\n%s\n" "${SYS_PWD}" "${ORDS_PUBLIC_USER_PWD}" > "${TEMP_PASS_FILE}"
  sudo chown ubuntu:ords "${TEMP_PASS_FILE}"
  chmod 640 "${TEMP_PASS_FILE}"
)

# Run ORDS install as user ords (omitting --db-pool default as ORDS 26.3 uses default pool automatically)
echo "3. Running non-interactive ORDS install (connecting to VM1)..."
sudo -u ords /usr/local/bin/ords --config /etc/ords/config install \
  --admin-user SYS \
  --proxy-user \
  --db-hostname "${VM1_IP}" \
  --db-port "${DB_PORT}" \
  --db-servicename "${DB_SERVICE}" \
  --feature-sdw false \
  --log-folder /var/log/ords \
  --password-stdin < "${TEMP_PASS_FILE}"

# Securely shred temp password file
sudo shred -u "${TEMP_PASS_FILE}"

# Configure standalone settings
echo "4. Configuring ORDS standalone parameters..."
sudo -u ords /usr/local/bin/ords --config /etc/ords/config config set plsql.gateway.mode proxied
sudo -u ords /usr/local/bin/ords --config /etc/ords/config config set standalone.http.port 8080
sudo -u ords /usr/local/bin/ords --config /etc/ords/config config set standalone.static.path /opt/apex/images
sudo -u ords /usr/local/bin/ords --config /etc/ords/config config set standalone.static.context.path /i
sudo -u ords /usr/local/bin/ords --config /etc/ords/config config set security.requestValidationFunction ords_util.authorize_plsql_gateway

echo "ORDS Config List:"
sudo -u ords /usr/local/bin/ords --config /etc/ords/config config list

# Run sys.validate_apex and assign APP_SVC_PROFILE
echo "5. Validating APEX and setting ORDS_PUBLIC_USER profile..."
sql -thin -S /nolog <<EOF
connect sys/"${SYS_PWD}"@//${VM1_IP}:${DB_PORT}/${DB_SERVICE} as sysdba
set serveroutput on
begin
  sys.validate_apex;
end;
/
alter user ORDS_PUBLIC_USER profile APP_SVC_PROFILE;
exit;
EOF

# Create ords.service systemd daemon
echo "6. Setting up ords.service daemon..."
JAVA_BIN=$(readlink -f $(which java))
JAVA_DIR=$(dirname $(dirname "${JAVA_BIN}"))

sudo tee /etc/systemd/system/ords.service > /dev/null <<EOF
[Unit]
Description=Oracle REST Data Services (ORDS)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=ords
Group=ords
ExecStart=/usr/local/bin/ords --config /etc/ords/config serve
Restart=on-failure
RestartSec=10
Environment="JAVA_HOME=${JAVA_DIR}"
Environment="JAVA_TOOL_OPTIONS=-Xms512m -Xmx1g"

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable ords.service
sudo systemctl restart ords.service

# Verify service
echo "7. Verifying ORDS service..."
sleep 5
sudo systemctl status ords.service --no-pager

echo ""
echo "8. Verifying HTTP endpoints..."
curl -sI http://localhost:8080/ords/ | head -n 5
curl -sI http://localhost:8080/i/apex_version.txt | head -n 5

echo ""
echo "=== Phase 4 Complete! ==="
