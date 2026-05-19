# Build Workflow

This repository builds and packages `nerdctl-full` from `nerdctl` `v2.2.2` with a small local Dockerfile patch for optional apt snapshot pinning.

## Targets

- Debian package: `nerdctl-full_2.2.2-0sans1_amd64.deb`
- Install prefix inside package: `/usr/local/bin`

## Scripts

- `scripts/online-prefetch.sh`
  - Fetches module dependencies and writes a prefetch artifact manifest.
- `scripts/bootstrap-buildkit.sh`
  - Downloads upstream BuildKit release binaries into `tools/buildkit/bin`.
- `scripts/build-nerdctl-full.sh`
  - Tries Docker-free build first (`nerdctl build`), then Docker fallback.
  - Set `ALLOW_DOCKER_FALLBACK=0` to force Docker-free only.
- `scripts/package-deb.sh`
  - Packages the `nerdctl-full` tarball into a Debian package.
- `scripts/package-minimal-deb.sh`
  - Fallback package when full tarball build is unavailable.
  - Produces `nerdctl-full` package with `nerdctl` and rootless helper scripts.
- `scripts/verify-deb.sh`
  - Verifies package filename, package metadata, and required `/usr/local/bin` payload paths.
- `scripts/build-package-verify.sh`
  - One-shot wrapper for prefetch -> build -> package -> verify.
  - Optional rootless validation: `RUN_ROOTLESS_VALIDATION=1 ./scripts/build-package-verify.sh`
- `scripts/verify-runtime-prereqs.sh`
  - Checks host runtime prerequisites for rootless operation.
- `scripts/postinstall-configure-systemd.sh`
  - Root-level post-install helper to force systemd `containerd.service` to use `/usr/local/bin/containerd`.
- `scripts/postinstall-revert-systemd.sh`
  - Root-level rollback helper to remove the override and return `containerd.service` to distro defaults.
- `scripts/validate-rootless.sh`
  - Validates rootless setup and runs a smoke test.
- `scripts/offline-build.sh`
  - Runs build with Docker fallback disabled and then packages.

## Typical Flow

1. `./scripts/online-prefetch.sh`
2. `./scripts/build-nerdctl-full.sh`
3. `./scripts/package-deb.sh`
4. `./scripts/verify-deb.sh`
5. `./scripts/validate-rootless.sh`

Fast path:

- `./scripts/build-package-verify.sh`

Check host prerequisites:

- `./scripts/verify-runtime-prereqs.sh`
- strict mode: `./scripts/verify-runtime-prereqs.sh --strict-user-systemd`
- CI mode (all checks must pass): `./scripts/verify-runtime-prereqs.sh --ci-mode`
- maximum strictness: `./scripts/verify-runtime-prereqs.sh --ci-mode --strict-user-systemd`

After package install (system service override):

- `sudo ./scripts/postinstall-configure-systemd.sh`

Rollback to distro service behavior:

- `sudo ./scripts/postinstall-revert-systemd.sh`

## Notes

- If CNI bridge plugin is not available, rootless validation falls back to `--net=host` for the smoke test.
- Build script auto-downloads BuildKit to `tools/buildkit/bin` when missing.
- Optional apt snapshot pinning is supported for build reproducibility:
  - `APT_SNAPSHOT=20260518T000000Z ./scripts/build-nerdctl-full.sh`
- Full dependency and prerequisite reference: `DEPENDENCIES.md`
- Current checklist and upcoming work: `TODO.md`

## CI Mode

For automated testing and CI pipelines, use the `--ci-mode` flag:

```bash
./scripts/verify-runtime-prereqs.sh --ci-mode
```

In CI mode:
- All warnings are treated as errors (non-zero exit on any issue)
- Output includes timestamps and clear PASS/FAIL status
- No ANSI color codes (CI-friendly logging)
- Suitable for GitHub Actions, Jenkins, and other CI systems

Combine with `--strict-user-systemd` for maximum strictness:

```bash
./scripts/verify-runtime-prereqs.sh --ci-mode --strict-user-systemd
```

## Lessons Learned

- Debian sid may not provide all required build/runtime tooling in apt; local upstream bootstrap scripts are necessary.
- Rootless containerd can run without CNI bridge, but default networking checks fail unless CNI plugins are installed.
- Rootless `nerdctl build` requires both `buildctl` and an active `buildkit.service`; having binaries alone is not sufficient.
- Verifying package payload paths is important to guarantee `/usr/local/bin` precedence is preserved.
