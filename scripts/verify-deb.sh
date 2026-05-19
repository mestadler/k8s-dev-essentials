#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACTS_DIR="${ROOT_DIR}/artifacts"
EXPECTED_NAME="nerdctl-full"
EXPECTED_VERSION="2.2.2-0sans1"
EXPECTED_ARCH="amd64"
EXPECTED_FILE="${ARTIFACTS_DIR}/${EXPECTED_NAME}_${EXPECTED_VERSION}_${EXPECTED_ARCH}.deb"

log() {
  printf '[verify-deb] %s\n' "$*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  }
}

require_cmd dpkg-deb

DEB_FILE="${1:-${EXPECTED_FILE}}"

if [[ ! -f "${DEB_FILE}" ]]; then
  printf 'Deb file not found: %s\n' "${DEB_FILE}" >&2
  exit 1
fi

BASE_NAME="$(basename "${DEB_FILE}")"
if [[ "${BASE_NAME}" != "${EXPECTED_NAME}_${EXPECTED_VERSION}_${EXPECTED_ARCH}.deb" ]]; then
  printf 'Unexpected deb filename: %s\n' "${BASE_NAME}" >&2
  printf 'Expected: %s_%s_%s.deb\n' "${EXPECTED_NAME}" "${EXPECTED_VERSION}" "${EXPECTED_ARCH}" >&2
  exit 1
fi

log "Verifying package metadata"
PKG_NAME="$(dpkg-deb -f "${DEB_FILE}" Package)"
PKG_VERSION="$(dpkg-deb -f "${DEB_FILE}" Version)"
PKG_ARCH="$(dpkg-deb -f "${DEB_FILE}" Architecture)"

[[ "${PKG_NAME}" == "${EXPECTED_NAME}" ]] || { printf 'Package name mismatch: %s\n' "${PKG_NAME}" >&2; exit 1; }
[[ "${PKG_VERSION}" == "${EXPECTED_VERSION}" ]] || { printf 'Version mismatch: %s\n' "${PKG_VERSION}" >&2; exit 1; }
[[ "${PKG_ARCH}" == "${EXPECTED_ARCH}" ]] || { printf 'Architecture mismatch: %s\n' "${PKG_ARCH}" >&2; exit 1; }

log "Verifying required payload paths"
LISTING="$(dpkg-deb -c "${DEB_FILE}")"
for path in ./usr/local/bin/nerdctl ./usr/local/bin/containerd-rootless.sh ./usr/local/bin/containerd-rootless-setuptool.sh; do
  if ! grep -q " ${path}$" <<<"${LISTING}"; then
    printf 'Missing required payload path: %s\n' "${path}" >&2
    exit 1
  fi
done

if grep -q " ./usr/bin/" <<<"${LISTING}"; then
  printf 'Unexpected /usr/bin payload detected\n' >&2
  exit 1
fi

log "Deb verification passed: ${DEB_FILE}"
