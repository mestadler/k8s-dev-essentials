# k8s-dev-essentials

Build and package a Docker-free `nerdctl-full` toolchain for Debian-based developer environments.

Source baseline is `nerdctl` `v2.2.2` plus a small local Dockerfile patch to support optional apt snapshot pinning for reproducible builds.

This repo provides scripts to:

- build `nerdctl-full` from pinned upstream source (`v2.2.2`)
- package it as `nerdctl-full_2.2.2-0sans1_amd64.deb`
- verify package contents and host runtime prerequisites
- configure and rollback systemd `containerd` service overrides

## Quick Start

Clone with submodules:

```bash
git clone --recurse-submodules https://github.com/mestadler/k8s-dev-essentials.git
cd k8s-dev-essentials
```

If already cloned without submodules:

```bash
git submodule update --init --recursive
```

Run the full build/package/verify pipeline:

```bash
./scripts/build-package-verify.sh
```

Artifacts are written to `artifacts/`.

## Common Commands

- Verify host prerequisites:
  - `./scripts/verify-runtime-prereqs.sh`
  - `./scripts/verify-runtime-prereqs.sh --ci-mode` (CI-friendly, strict)
- Build with optional apt snapshot pinning:
  - `APT_SNAPSHOT=20260518T000000Z ./scripts/build-nerdctl-full.sh`
- Configure systemd to use `/usr/local/bin/containerd`:
  - `sudo ./scripts/postinstall-configure-systemd.sh`
- Roll back to distro systemd defaults:
  - `sudo ./scripts/postinstall-revert-systemd.sh`

## Notes

- Main workflow docs: `BUILD.md`
- Dependency and runtime reference: `DEPENDENCIES.md`
- Current project checklist and next steps: `TODO.md`
