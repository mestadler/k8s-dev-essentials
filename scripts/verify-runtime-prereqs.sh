#!/usr/bin/env bash
set -euo pipefail

missing=0
strict_user_systemd=0

if [[ "${1:-}" == "--strict-user-systemd" ]]; then
  strict_user_systemd=1
fi

check_cmd() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    printf '[prereqs] ok: %s\n' "$name"
  else
    printf '[prereqs] missing: %s\n' "$name" >&2
    missing=1
  fi
}

check_path() {
  local p="$1"
  if [[ -e "$p" ]]; then
    printf '[prereqs] ok: %s\n' "$p"
  else
    printf '[prereqs] missing: %s\n' "$p" >&2
    missing=1
  fi
}

printf '[prereqs] checking required commands\n'
check_cmd nerdctl
check_cmd containerd
check_cmd rootlesskit
check_cmd newuidmap
check_cmd newgidmap
check_cmd slirp4netns
check_cmd systemctl

printf '[prereqs] checking common rootless paths\n'
check_path /etc/subuid
check_path /etc/subgid

if [[ -x /usr/lib/cni/bridge ]]; then
  printf '[prereqs] ok: /usr/lib/cni/bridge\n'
else
  printf '[prereqs] missing: /usr/lib/cni/bridge (install containernetworking-plugins)\n' >&2
  missing=1
fi

printf '[prereqs] checking systemd user context\n'
if systemctl --user is-system-running >/dev/null 2>&1; then
  printf '[prereqs] ok: systemctl --user context available\n'
else
  if [[ "$strict_user_systemd" -eq 1 ]]; then
    printf '[prereqs] missing: systemctl --user context not fully active (strict mode)\n' >&2
    missing=1
  else
    printf '[prereqs] warning: systemctl --user context not fully active\n' >&2
  fi
fi

if [[ "$missing" -ne 0 ]]; then
  printf '[prereqs] one or more required prerequisites are missing\n' >&2
  exit 1
fi

printf '[prereqs] all required prerequisites found\n'
