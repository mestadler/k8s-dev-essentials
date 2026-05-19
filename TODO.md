# TODO

## Completed

- [x] Build Docker-free `nerdctl-full` flow targeting upstream `v2.2.2`
- [x] Package `.deb` as `nerdctl-full_2.2.2-0sans1_amd64.deb`
- [x] Install package payload binaries under `/usr/local/bin`
- [x] Add package verification script (`scripts/verify-deb.sh`)
- [x] Add runtime prerequisite checks (`scripts/verify-runtime-prereqs.sh`)
- [x] Add strict prerequisite mode (`--strict-user-systemd`)
- [x] Add systemd configure/revert helpers for `containerd.service`
- [x] Add optional apt snapshot pinning support (`APT_SNAPSHOT`)
- [x] Add one-shot pipeline wrapper (`scripts/build-package-verify.sh`)
- [x] Add dependency and workflow documentation

## Next

- [ ] Optional: split `nerdctl-full` into multiple Debian packages per tool group
- [ ] Optional: add CI pipeline (GitHub Actions or Forgejo)
- [ ] Optional: add release watcher for upstream `nerdctl` tags
- [ ] Optional: add package signing and checksum publishing workflow
- [ ] Optional: add runtime selection verification script for systemd + PATH
  - [x] Add --strict-user-systemd flag
  - [ ] Add --ci-mode flag (implementing now)
  - [ ] Update documentation
  - [ ] **Future**: revisit for comprehensive pluggable severity system (see Option B notes)

## Pause Point

Current state is ready for initial upstream push and iterative hardening.
