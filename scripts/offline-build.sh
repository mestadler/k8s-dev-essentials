#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() {
  printf '[offline] %s\n' "$*"
}

if [[ ! -f "${ROOT_DIR}/artifacts/prefetch/nerdctl-go-mod-vendor-v2.2.2.tar.gz" ]]; then
  printf 'Missing prefetch cache tarball. Run scripts/online-prefetch.sh first.\n' >&2
  exit 1
fi

log "Running build with Docker fallback disabled"
ALLOW_DOCKER_FALLBACK=0 "${ROOT_DIR}/scripts/build-nerdctl-full.sh"

log "Building deb package"
"${ROOT_DIR}/scripts/package-deb.sh"

log "Offline workflow finished"
