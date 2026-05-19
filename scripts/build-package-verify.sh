#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() {
  printf '[pipeline] %s\n' "$*"
}

run_step() {
  local step="$1"
  shift
  log "Starting: ${step}"
  "$@"
  log "Done: ${step}"
}

run_step "online prefetch" "${ROOT_DIR}/scripts/online-prefetch.sh"
run_step "build nerdctl-full" "${ROOT_DIR}/scripts/build-nerdctl-full.sh"
run_step "package deb" "${ROOT_DIR}/scripts/package-deb.sh"
run_step "verify deb" "${ROOT_DIR}/scripts/verify-deb.sh"

if [[ "${RUN_ROOTLESS_VALIDATION:-0}" == "1" ]]; then
  run_step "validate rootless" "${ROOT_DIR}/scripts/validate-rootless.sh"
fi

log "Pipeline completed successfully"
