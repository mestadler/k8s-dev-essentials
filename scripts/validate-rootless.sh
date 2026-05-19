#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETUP_TOOL="${ROOT_DIR}/nerdctl/extras/rootless/containerd-rootless-setuptool.sh"
export PATH="${ROOT_DIR}/nerdctl/_output:${ROOT_DIR}/nerdctl/extras/rootless:${PATH}"

log() {
  printf '[rootless] %s\n' "$*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  }
}

require_cmd nerdctl
require_cmd newuidmap
require_cmd newgidmap
require_cmd rootlesskit
require_cmd systemctl

if [[ ! -x "${SETUP_TOOL}" ]]; then
  printf 'Missing setup tool: %s\n' "${SETUP_TOOL}" >&2
  exit 1
fi

log "Checking subuid/subgid entries for $(id -un)"
grep -q "^$(id -un):" /etc/subuid
grep -q "^$(id -un):" /etc/subgid

log "Running rootless setup check"
"${SETUP_TOOL}" check

log "Ensuring rootless containerd is installed"
"${SETUP_TOOL}" install

log "Checking user service status"
systemctl --user --no-pager --full status containerd.service >/dev/null

log "Running rootless nerdctl smoke test"
if ! nerdctl run --rm hello-world; then
  if [[ ! -x "/usr/lib/cni/bridge" ]]; then
    printf 'CNI bridge plugin missing at /usr/lib/cni/bridge\n' >&2
    printf 'Install it (Debian): sudo apt install -y containernetworking-plugins\n' >&2
  fi
  log "Retrying smoke test with host networking"
  nerdctl run --rm --net=host hello-world
fi

log "Collecting nerdctl info"
nerdctl info >/dev/null

log "Rootless validation passed"
