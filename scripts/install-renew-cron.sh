#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CRON_FILE="/etc/cron.d/nginx-lab-letsencrypt"
ENV_PATH="${ROOT_DIR}/.env.prod"
SCRIPT_PATH="${ROOT_DIR}/scripts/renew-letsencrypt.sh"

cat > "${CRON_FILE}" <<EOF
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
0 3 * * * root ENV_FILE=${ENV_PATH} ${SCRIPT_PATH} >> /var/log/nginx-lab-letsencrypt.log 2>&1
EOF

chmod 644 "${CRON_FILE}"
echo "Cron installe dans ${CRON_FILE}"
