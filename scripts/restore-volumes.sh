#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/${ENV_FILE:-.env.dev}"
BACKUP_PATH="${1:-}"

if [[ -z "${BACKUP_PATH}" ]]; then
  echo "Usage: ENV_FILE=.env.prod ./scripts/restore-volumes.sh /chemin/vers/le/dossier-backup" >&2
  exit 1
fi

if [[ ! -d "${BACKUP_PATH}" ]]; then
  echo "Dossier de sauvegarde introuvable: ${BACKUP_PATH}" >&2
  exit 1
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Fichier d'environnement introuvable: ${ENV_FILE}" >&2
  exit 1
fi

set -a
source "${ENV_FILE}"
set +a

restore_volume() {
  local volume_name="$1"
  local archive_name="$2"

  if [[ ! -f "${BACKUP_PATH}/${archive_name}" ]]; then
    echo "Archive manquante: ${BACKUP_PATH}/${archive_name}" >&2
    exit 1
  fi

  docker volume create "${volume_name}" >/dev/null

  docker run --rm \
    -v "${volume_name}:/target" \
    -v "${BACKUP_PATH}:/backup:ro" \
    alpine:3.22 \
    sh -lc "rm -rf /target/* /target/.[!.]* /target/..?* && tar xzf /backup/${archive_name} -C /target"
}

restore_volume "${COMPOSE_PROJECT_NAME}_grafana_data" "grafana-data.tar.gz"
restore_volume "${COMPOSE_PROJECT_NAME}_prometheus_data" "prometheus-data.tar.gz"

echo "Restauration terminee depuis ${BACKUP_PATH}"
