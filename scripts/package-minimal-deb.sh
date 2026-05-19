#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NERDCTL_DIR="${ROOT_DIR}/nerdctl"
VERSION="2.2.2-0sans1"
ARCH="amd64"
PACKAGE="nerdctl-full"
WORK_DIR="${ROOT_DIR}/artifacts/package-minimal"
PKG_ROOT="${WORK_DIR}/root"
DEB_OUT="${ROOT_DIR}/artifacts/${PACKAGE}_${VERSION}_${ARCH}.deb"

log() {
  printf '[package-minimal] %s\n' "$*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  }
}

require_cmd dpkg-deb
require_cmd make

log "Building nerdctl binary"
make -C "${NERDCTL_DIR}" binaries

rm -rf "${WORK_DIR}"
mkdir -p "${PKG_ROOT}/DEBIAN" "${PKG_ROOT}/usr/local/bin" "${PKG_ROOT}/usr/local/share/doc/nerdctl-full"

install -m 0755 "${NERDCTL_DIR}/_output/nerdctl" "${PKG_ROOT}/usr/local/bin/nerdctl"
install -m 0755 "${NERDCTL_DIR}/extras/rootless/containerd-rootless.sh" "${PKG_ROOT}/usr/local/bin/containerd-rootless.sh"
install -m 0755 "${NERDCTL_DIR}/extras/rootless/containerd-rootless-setuptool.sh" "${PKG_ROOT}/usr/local/bin/containerd-rootless-setuptool.sh"
cp -a "${NERDCTL_DIR}/docs/." "${PKG_ROOT}/usr/local/share/doc/nerdctl-full/"

cat >"${PKG_ROOT}/DEBIAN/control" <<EOF
Package: ${PACKAGE}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Maintainer: sans local build
Depends: adduser
Recommends: uidmap, slirp4netns, containernetworking-plugins, dbus-user-session
Description: minimal nerdctl package when full bundle build is unavailable
 Includes nerdctl and rootless helper scripts under /usr/local/bin.
EOF

dpkg-deb --root-owner-group --build "${PKG_ROOT}" "${DEB_OUT}"
log "Wrote ${DEB_OUT}"
