#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NERDCTL_DIR="${ROOT_DIR}/nerdctl"
VERSION="2.2.2-0sans1"
UPSTREAM_VERSION="2.2.2"
ARCH="amd64"
PACKAGE="nerdctl-full"
WORK_DIR="${ROOT_DIR}/artifacts/package"
PKG_ROOT="${WORK_DIR}/root"
TARBALL="${NERDCTL_DIR}/_output/nerdctl-full-${UPSTREAM_VERSION}-linux-${ARCH}.tar.gz"
DEB_OUT="${ROOT_DIR}/artifacts/${PACKAGE}_${VERSION}_${ARCH}.deb"

log() {
  printf '[package] %s\n' "$*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  }
}

require_cmd dpkg-deb
require_cmd tar

if [[ ! -f "${TARBALL}" ]]; then
  printf 'Missing full tarball: %s\n' "${TARBALL}" >&2
  exit 1
fi

rm -rf "${WORK_DIR}"
mkdir -p "${WORK_DIR}" "${PKG_ROOT}/DEBIAN" "${PKG_ROOT}/usr/local/bin" "${PKG_ROOT}/usr/local/share/doc/nerdctl-full"

log "Extracting full tarball"
tar -xzf "${TARBALL}" -C "${WORK_DIR}"

BIN_SOURCE=""
if [[ -d "${WORK_DIR}/bin" ]]; then
  BIN_SOURCE="${WORK_DIR}/bin"
elif [[ -d "${WORK_DIR}/out/bin" ]]; then
  BIN_SOURCE="${WORK_DIR}/out/bin"
else
  printf 'Could not locate bin directory in %s\n' "${TARBALL}" >&2
  exit 1
fi

log "Installing binaries to /usr/local/bin"
find "${BIN_SOURCE}" -maxdepth 1 -type f -exec install -m 0755 {} "${PKG_ROOT}/usr/local/bin/" \;

if [[ -d "${WORK_DIR}/share/doc/nerdctl-full" ]]; then
  cp -a "${WORK_DIR}/share/doc/nerdctl-full/." "${PKG_ROOT}/usr/local/share/doc/nerdctl-full/"
elif [[ -d "${WORK_DIR}/out/share/doc/nerdctl-full" ]]; then
  cp -a "${WORK_DIR}/out/share/doc/nerdctl-full/." "${PKG_ROOT}/usr/local/share/doc/nerdctl-full/"
fi

cat >"${PKG_ROOT}/DEBIAN/control" <<EOF
Package: ${PACKAGE}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Maintainer: sans local build
Depends: adduser
Recommends: uidmap, slirp4netns, containernetworking-plugins, dbus-user-session
Description: nerdctl full distribution packaged for local systems
 Built from upstream nerdctl ${UPSTREAM_VERSION} with local sans delta.
EOF

cat >"${PKG_ROOT}/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
chmod 0755 /usr/local/bin/* || true
exit 0
EOF
chmod 0755 "${PKG_ROOT}/DEBIAN/postinst"

log "Building deb package"
mkdir -p "${ROOT_DIR}/artifacts"
dpkg-deb --root-owner-group --build "${PKG_ROOT}" "${DEB_OUT}"
log "Wrote ${DEB_OUT}"
