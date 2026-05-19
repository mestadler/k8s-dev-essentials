# Dependencies

This project builds `nerdctl-full` from upstream `v2.2.2` and packages it as:

- `nerdctl-full_2.2.2-0sans1_amd64.deb`

## Bundled In The Package

The `.deb` payload installs tools under `/usr/local/bin`, including:

- `nerdctl`
- `containerd`, `ctr`, `containerd-shim-runc-v2`
- `runc`
- `buildkitd`, `buildctl`
- `rootlesskit`, `rootlessctl`
- `slirp4netns`
- `fuse-overlayfs`, `containerd-fuse-overlayfs-grpc`
- `containerd-stargz-grpc`, `stargz-fuse-manager`, `stargz-store-helper`
- `bypass4netns`, `bypass4netnsd`
- `tini`
- `buildg`
- `containerd-rootless.sh`, `containerd-rootless-setuptool.sh`

Most binaries in the built payload are statically linked.

## Package Metadata Dependencies

Current package metadata in control file:

- `Depends: adduser`
- `Recommends: uidmap, slirp4netns, containernetworking-plugins, dbus-user-session`

## Host Runtime Requirements

Expected on host for rootless workflows:

- `rootlesskit`
- `newuidmap`, `newgidmap` (`uidmap` package)
- `slirp4netns`
- CNI bridge plugin at `/usr/lib/cni/bridge` (`containernetworking-plugins` package)
- `/etc/subuid` and `/etc/subgid` entries for the user
- working `systemctl --user` session

Check host requirements with:

- `./scripts/verify-runtime-prereqs.sh`
- `./scripts/verify-runtime-prereqs.sh --strict-user-systemd` (fails on user systemd context warnings)

## Build-Time Inputs

Build-time dependencies are resolved from upstream Dockerfile and include:

- pinned component tags/versions in `nerdctl/Dockerfile`
- Go modules from upstream sources
- release tarballs/binaries from upstream GitHub projects

The prefetch pipeline captures key inputs:

- `./scripts/online-prefetch.sh`

## Optional Apt Snapshot Pinning

Build supports optional apt snapshot pinning via environment variable:

- `APT_SNAPSHOT=<timestamp>`

Example:

- `APT_SNAPSHOT=20260518T000000Z ./scripts/build-nerdctl-full.sh`

When set, Docker build uses `snapshot.debian.org` for `apt` in the build container.
