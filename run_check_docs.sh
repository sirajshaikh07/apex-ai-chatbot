#!/usr/bin/env bash
set -euo pipefail

source /home/ubuntu/project/values.env
source /home/ubuntu/.secrets.env

/usr/local/bin/sql -thin AIDEMO/"${AIDEMO_PWD}"@//${VM1_IP}:${DB_PORT}/${DB_SERVICE} @/home/ubuntu/docs/check_docs.sql
