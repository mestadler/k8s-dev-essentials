#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NERDCTL_DIR="${ROOT_DIR}/nerdctl"
TOOLS_DIR="${ROOT_DIR}/tools/buildkit"
BIN_DIR="${TOOLS_DIR}/bin"
ARCH="amd64"
OS="linux"

log() {
  printf '[buildkit-bootstrap] %s\n' "$*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  }
}

require_cmd curl
require_cmd tar

DEFAULT_VERSION="$(grep -E '^ARG BUILDKIT_VERSION=' "${NERDCTL_DIR}/Dockerfile" | head -n 1 | cut -d= -f2 | cut -d'@' -f1)"
VERSION="${1:-${DEFAULT_VERSION}}"

if [[ -z "${VERSION}" ]]; then
  printf 'Unable to determine BuildKit version. Pass version explicitly.\n' >&2
  exit 1
fi

mkdir -p "${TOOLS_DIR}" "${BIN_DIR}"
TARBALL="${TOOLS_DIR}/buildkit-${VERSION}.${OS}-${ARCH}.tar.gz"
URL="https://github.com/moby/buildkit/releases/download/${VERSION}/buildkit-${VERSION}.${OS}-${ARCH}.tar.gz"

log "Downloading ${URL}"
curl -fL --retry 5 --retry-delay 3 -o "${TARBALL}" "${URL}"

log "Extracting BuildKit tools"
tar -xzf "${TARBALL}" -C "${TOOLS_DIR}"

if [[ -x "${TOOLS_DIR}/bin/buildctl" && -x "${TOOLS_DIR}/bin/buildkitd" ]]; then
  log "BuildKit binaries ready in ${BIN_DIR}"
else
  printf 'Expected buildctl/buildkitd were not found after extraction.\n' >&2
  exit 1
fi

mkdir -p "${ROOT_DIR}/artifacts"
sha256sum "${TARBALL}" >"${ROOT_DIR}/artifacts/buildkit-${VERSION}.${OS}-${ARCH}.sha256"
log "Wrote checksum artifacts/buildkit-${VERSION}.${OS}-${ARCH}.sha256"
