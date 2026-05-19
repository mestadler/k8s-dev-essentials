#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="containerd"
OVERRIDE_DIR="/etc/systemd/system/${SERVICE_NAME}.service.d"
OVERRIDE_FILE="${OVERRIDE_DIR}/override.conf"

log() {
  printf '[postinstall-revert] %s\n' "$*"
}

if [[ "${EUID}" -ne 0 ]]; then
  printf 'Run as root (use sudo).\n' >&2
  exit 1
fi

if [[ -f "${OVERRIDE_FILE}" ]]; then
  rm -f "${OVERRIDE_FILE}"
  log "Removed ${OVERRIDE_FILE}"
else
  log "No override file present at ${OVERRIDE_FILE}"
fi

if [[ -d "${OVERRIDE_DIR}" ]] && [[ -z "$(ls -A "${OVERRIDE_DIR}")" ]]; then
  rmdir "${OVERRIDE_DIR}"
  log "Removed empty directory ${OVERRIDE_DIR}"
fi

systemctl daemon-reload
systemctl restart "${SERVICE_NAME}.service"

log "Restarted ${SERVICE_NAME}.service with distro unit defaults"
log "Current unit and ExecStart:"
systemctl cat "${SERVICE_NAME}.service"
