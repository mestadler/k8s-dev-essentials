#!/usr/bin/env bash
# TODO: Future enhancement (Option B) - Pluggable severity system
# - Allow configurable severity levels per check (INFO, WARN, ERROR)
# - Support .prereqs-config.yaml for project-specific requirements
# - Add JSON output format for programmatic consumption
# See: https://github.com/mestadler/k8s-dev-essentials/issues/2

set -euo pipefail

missing=0
strict_user_systemd=0
ci_mode=0

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict-user-systemd)
      strict_user_systemd=1
      shift
      ;;
    --ci-mode)
      ci_mode=1
      shift
      ;;
    --help|-h)
      echo "Usage: $(basename "$0") [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --strict-user-systemd  Treat systemd user context warning as error"
      echo "  --ci-mode              CI-friendly mode: warnings become errors, optimized output"
      echo "  --help, -h             Show this help message"
      echo ""
      echo "Examples:"
      echo "  $(basename "$0")                          # Local development mode"
      echo "  $(basename "$0") --ci-mode                # CI pipeline mode"
      echo "  $(basename "$0") --ci-mode --strict-user-systemd  # Maximum strictness"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Use --help for usage information" >&2
      exit 1
      ;;
  esac
done

# CI mode output formatting
output() {
  local level="$1"
  local message="$2"
  
  if [[ "$ci_mode" -eq 1 ]]; then
    # CI-friendly format: timestamp + clear status
    local timestamp
    timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    printf '[%s] [%s] %s\n' "$timestamp" "$level" "$message"
  else
    # Standard format
    printf '[prereqs] %s: %s\n' "$level" "$message"
  fi
}

check_cmd() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    output "ok" "$name"
  else
    output "missing" "$name" >&2
    missing=1
  fi
}

check_path() {
  local p="$1"
  if [[ -e "$p" ]]; then
    output "ok" "$p"
  else
    output "missing" "$p" >&2
    missing=1
  fi
}

output "info" "checking required commands"
check_cmd nerdctl
check_cmd containerd
check_cmd rootlesskit
check_cmd newuidmap
check_cmd newgidmap
check_cmd slirp4netns
check_cmd systemctl

output "info" "checking common rootless paths"
check_path /etc/subuid
check_path /etc/subgid

if [[ -x /usr/lib/cni/bridge ]]; then
  output "ok" "/usr/lib/cni/bridge"
else
  output "missing" "/usr/lib/cni/bridge (install containernetworking-plugins)" >&2
  missing=1
fi

output "info" "checking systemd user context"
if systemctl --user is-system-running >/dev/null 2>&1; then
  output "ok" "systemctl --user context available"
else
  # In CI mode or strict mode, treat systemd context as error
  if [[ "$strict_user_systemd" -eq 1 ]] || [[ "$ci_mode" -eq 1 ]]; then
    mode_label=""
    if [[ "$strict_user_systemd" -eq 1 ]]; then
      mode_label=" (strict mode)"
    elif [[ "$ci_mode" -eq 1 ]]; then
      mode_label=" (CI mode)"
    fi
    output "missing" "systemctl --user context not fully active${mode_label}" >&2
    missing=1
  else
    output "warning" "systemctl --user context not fully active" >&2
  fi
fi

if [[ "$missing" -ne 0 ]]; then
  if [[ "$ci_mode" -eq 1 ]]; then
    output "FAIL" "one or more required prerequisites are missing"
  else
    output "error" "one or more required prerequisites are missing"
  fi >&2
  exit 1
fi

if [[ "$ci_mode" -eq 1 ]]; then
  output "PASS" "all required prerequisites found"
else
  output "ok" "all required prerequisites found"
fi
