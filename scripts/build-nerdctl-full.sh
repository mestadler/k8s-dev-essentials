#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NERDCTL_DIR="${ROOT_DIR}/nerdctl"
OUT_DIR="${NERDCTL_DIR}/_output"
TAG="v2.2.2"
ARCH="amd64"
VERSION="2.2.2"
FULL_TARBALL="${OUT_DIR}/nerdctl-full-${VERSION}-linux-${ARCH}.tar.gz"
ALLOW_DOCKER_FALLBACK="${ALLOW_DOCKER_FALLBACK:-1}"
export PATH="${ROOT_DIR}/tools/buildkit/bin:${ROOT_DIR}/nerdctl/_output:${ROOT_DIR}/nerdctl/extras/rootless:${HOME}/.local/bin:${PATH}"

log() {
  printf '[build] %s\n' "$*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  }
}

require_cmd git
require_cmd make

ensure_buildkit_for_rootless() {
  if ! command -v buildctl >/dev/null 2>&1 || ! command -v buildkitd >/dev/null 2>&1; then
    if [[ -x "${ROOT_DIR}/scripts/bootstrap-buildkit.sh" ]]; then
      log "buildctl/buildkitd not found; downloading BuildKit locally"
      "${ROOT_DIR}/scripts/bootstrap-buildkit.sh"
    fi
  fi
  if ! command -v buildctl >/dev/null 2>&1 || ! command -v buildkitd >/dev/null 2>&1; then
    log "BuildKit binaries are unavailable"
    return 1
  fi
  if [[ -x "${NERDCTL_DIR}/extras/rootless/containerd-rootless-setuptool.sh" ]]; then
    if ! systemctl --user --no-pager --full status buildkit.service >/dev/null 2>&1; then
      log "Installing rootless BuildKit service"
      "${NERDCTL_DIR}/extras/rootless/containerd-rootless-setuptool.sh" install-buildkit-containerd || true
    fi
  fi
  systemctl --user start buildkit.service >/dev/null 2>&1 || true
  sleep 2
  if ! systemctl --user --no-pager --full status buildkit.service >/dev/null 2>&1; then
    log "buildkit.service is not active"
    return 1
  fi
  return 0
}

log "Pinning source to ${TAG}"
git -C "${NERDCTL_DIR}" fetch --tags
git -C "${NERDCTL_DIR}" checkout "${TAG}"

SHA="$(git -C "${NERDCTL_DIR}" rev-parse HEAD)"
mkdir -p "${ROOT_DIR}/artifacts"
cat >"${ROOT_DIR}/artifacts/build-metadata.txt" <<EOF
tag=${TAG}
version=${VERSION}
arch=${ARCH}
source_sha=${SHA}
apt_snapshot=${APT_SNAPSHOT:-}
timestamp_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

build_with_tool() {
  local tool="$1"
  local secret_arg=()
  log "Attempting full build with DOCKER=${tool}"
  rm -f "${OUT_DIR}/nerdctl-full-${VERSION}-linux-${ARCH}.tar" "${FULL_TARBALL}"
  if [[ -n "${GITHUB_TOKEN:-}" ]]; then
    secret_arg=(--secret id=github_token,env=GITHUB_TOKEN)
  fi
  local apt_arg=()
  if [[ -n "${APT_SNAPSHOT:-}" ]]; then
    apt_arg=(--build-arg "APT_SNAPSHOT=${APT_SNAPSHOT}")
  fi
  "${tool}" build \
    "${secret_arg[@]}" \
    "${apt_arg[@]}" \
    --output "type=tar,dest=${OUT_DIR}/nerdctl-full-${VERSION}-linux-${ARCH}.tar" \
    --target out-full \
    --platform "${ARCH}" \
    --build-arg GO_VERSION \
    -f "${NERDCTL_DIR}/Dockerfile" \
    "${NERDCTL_DIR}"
  gzip -9 "${OUT_DIR}/nerdctl-full-${VERSION}-linux-${ARCH}.tar"
}

NERDCTL_CLI=""
if command -v nerdctl >/dev/null 2>&1; then
  NERDCTL_CLI="nerdctl"
elif [[ -x "${NERDCTL_DIR}/_output/nerdctl" ]]; then
  NERDCTL_CLI="${NERDCTL_DIR}/_output/nerdctl"
fi

if [[ -n "${NERDCTL_CLI}" ]]; then
  if ensure_buildkit_for_rootless && build_with_tool "${NERDCTL_CLI}"; then
    log "Docker-free build succeeded"
    echo "build_mode=docker_free" >>"${ROOT_DIR}/artifacts/build-metadata.txt"
    exit 0
  fi
  log "Docker-free build failed; trying Docker fallback"
else
  log "nerdctl CLI not found; skipping Docker-free attempt"
fi

if [[ "${ALLOW_DOCKER_FALLBACK}" != "1" ]]; then
  log "Docker fallback disabled (ALLOW_DOCKER_FALLBACK=${ALLOW_DOCKER_FALLBACK})"
  exit 1
fi

require_cmd docker
if build_with_tool docker; then
  log "Docker fallback build succeeded"
  echo "build_mode=docker_fallback" >>"${ROOT_DIR}/artifacts/build-metadata.txt"
  exit 0
fi

log "Build failed for both Docker-free and fallback modes"
exit 1
