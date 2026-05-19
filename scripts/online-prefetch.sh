#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NERDCTL_DIR="${ROOT_DIR}/nerdctl"
PREFETCH_DIR="${ROOT_DIR}/artifacts/prefetch"

log() {
  printf '[prefetch] %s\n' "$*"
}

mkdir -p "${PREFETCH_DIR}"

log "Pinning nerdctl source to v2.2.2"
git -C "${NERDCTL_DIR}" fetch --tags
git -C "${NERDCTL_DIR}" checkout v2.2.2

log "Prefetching Go module dependencies"
go -C "${NERDCTL_DIR}" mod download
go -C "${NERDCTL_DIR}" mod vendor
tar -czf "${PREFETCH_DIR}/nerdctl-go-mod-vendor-v2.2.2.tar.gz" -C "${NERDCTL_DIR}" go.mod go.sum vendor

log "Capturing dependency URL manifest from Dockerfile"
grep -E "https://|git clone" "${NERDCTL_DIR}/Dockerfile" >"${PREFETCH_DIR}/dockerfile-network-inputs.txt" || true

if [[ -x "${ROOT_DIR}/scripts/bootstrap-buildkit.sh" ]]; then
  log "Prefetching BuildKit binary release"
  "${ROOT_DIR}/scripts/bootstrap-buildkit.sh"
fi

log "Writing checksums"
sha256sum "${PREFETCH_DIR}"/*.tar.gz >"${PREFETCH_DIR}/SHA256SUMS"

log "Online prefetch complete"
