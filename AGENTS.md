# AGENTS.md

This file defines how coding agents should work in this repository.

## Mission

Build and validate `nerdctl-full` with rootless support from upstream `nerdctl`, using a pinned release tag, and produce a Debian package artifact for local-dev workflows.

Current pinned target:

- Upstream tag: `v2.2.2`
- Host OS target: Debian sid
- Build scope: `nerdctl-full` + `.deb` artifact

## Repository Layout

- `./nerdctl/`: upstream clone used as source
- `./AGENTS.md`: agent policy and workflow
- Future: `./RUNBOOK.md` for end-user instructions (not part of this phase)

## Non-Negotiables

1. Do not use Docker for bootstrap/build/test.
2. Prefer pure `containerd` + `nerdctl` workflows.
3. Keep build steps local-dev focused.
4. Pin source to release tags (currently `v2.2.2`), not moving HEAD.
5. Design for offline rebuild capability after dependency prefetch.
6. Include rootless validation in every successful build cycle.

## Agent Operating Rules

### 1) Source Control and Pinning

- Treat `./nerdctl` as upstream source.
- Always check out the pinned tag before build work:
  - `git -C nerdctl fetch --tags`
  - `git -C nerdctl checkout v2.2.2`
- If the work requires patching upstream code, create a patch file in this repo instead of committing directly to upstream clone unless explicitly requested.

### 2) Toolchain Strategy (Forward-Looking)

- Prefer current stable Go available on Debian sid.
- Prefer upstream-supported versions of runtime dependencies.
- Record discovered versions in build notes when relevant.
- Do not hard-fail solely on newer compatible tool versions.

### 3) Offline-First Workflow

Agents should separate workflow into two modes:

- `online-prefetch`:
  - Resolve and download Go modules and any other required build inputs.
  - Capture/cache all required artifacts for later offline runs.
- `offline-build`:
  - Build using only local caches and pre-fetched artifacts.
  - Fail with actionable diagnostics if any network dependency remains.

When creating scripts or Make targets, keep these two modes explicit.

### 4) Build Targets

Primary output:

- `nerdctl-full` binaries/components for the pinned release.

Packaging output:

- Debian package (`.deb`) containing the built artifacts.

Packaging preference order:

1. Use native/upstream Debian packaging method if present in source.
2. If not available, use `nfpm` (Go-based) and keep packaging config in this repo.

### 5) Rootless Validation (Required)

A build is not complete until rootless checks pass.

Minimum validation flow to automate/document:

1. Install/configure rootless containerd tooling as needed (for example, `containerd-rootless-setuptool.sh install`).
2. Confirm rootless daemon/socket state is healthy.
3. Run a rootless smoke test with `nerdctl` (for example, `nerdctl run --rm hello-world`).
4. Verify `nerdctl` client/server info under rootless context.

Record command outputs in logs when run by agent tasks.

### 6) Local-Dev Scope

- Optimize for repeatable execution on a single Debian sid workstation.
- Do not add CI-only complexity in this phase.
- CI integration (GitHub Actions / Forgejo) is a future phase and should be left as optional notes/TODOs only.

## Expected Deliverables From Agent Changes

When agents implement or modify build logic, aim to include:

1. Scripted build entrypoint(s) for pinned tag builds.
2. Scripted packaging entrypoint for `.deb` artifact generation.
3. Rootless validation script or target.
4. Clear logs/artifact paths.
5. Short troubleshooting notes for Debian sid-specific issues.

## Safety and Reproducibility

- Keep destructive commands out of automation unless explicitly required.
- Make scripts idempotent where practical.
- Prefer explicit environment variables over hidden assumptions.
- Surface clear error messages for missing dependencies and offline cache gaps.

## Future Phase Notes (Do Not Implement By Default)

- Release watcher automation for new upstream nerdctl tags.
- CI pipelines that build/test/package on tag updates.
- Promotion/signing workflows for package distribution.
