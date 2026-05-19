#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="containerd"
TARGET_BIN="/usr/local/bin/containerd"
OVERRIDE_DIR="/etc/systemd/system/${SERVICE_NAME}.service.d"
OVERRIDE_FILE="${OVERRIDE_DIR}/override.conf"

log() {
  printf '[postinstall-systemd] %s\n' "$*"
}

if [[ "${EUID}" -ne 0 ]]; then
  printf 'Run as root (use sudo).\n' >&2
  exit 1
fi

if [[ ! -x "${TARGET_BIN}" ]]; then
  printf 'Expected binary not found or not executable: %s\n' "${TARGET_BIN}" >&2
  exit 1
fi

mkdir -p "${OVERRIDE_DIR}"

cat >"${OVERRIDE_FILE}" <<EOF
[Service]
ExecStart=
ExecStart=${TARGET_BIN}
EOF

log "Wrote ${OVERRIDE_FILE}"

systemctl daemon-reload
systemctl restart "${SERVICE_NAME}.service"

log "Restarted ${SERVICE_NAME}.service"
log "Current unit and ExecStart:"
systemctl cat "${SERVICE_NAME}.service"
