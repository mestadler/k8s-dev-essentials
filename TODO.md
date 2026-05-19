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
- [x] Add runtime selection verification script for systemd + PATH
  - [x] Add --strict-user-systemd flag
  - [x] Add --ci-mode flag (PR #7 merged)
  - [x] Update documentation (BUILD.md, README.md, DEPENDENCIES.md)
  - [ ] **Future**: revisit for comprehensive pluggable severity system (Option B)
- [x] Add CI pipeline (GitHub Actions)
  - [x] Build workflow for push to main and PRs
  - [x] Rootless validation in CI
  - [x] Artifact upload (.deb packages)

## Next

- [ ] **IN PROGRESS**: Migrate CI to Forgejo (git.sansnom.uk) with LFS support
- [ ] Optional: split `nerdctl-full` into multiple Debian packages per tool group
- [ ] Optional: add release watcher for upstream `nerdctl` tags
- [ ] Optional: add package signing and checksum publishing workflow
- [ ] **Future**: Runtime verification - comprehensive pluggable severity system (Option B)

## Pause Point

Current state is ready for initial upstream push and iterative hardening.
