# Caelestia Shell fork policy

This branch is the maintained shell companion for the `kensa/caelestia` rice fork. It is rebased conceptually on upstream release history, but fork changes are carried as small reviewable commits and packaged from immutable Git revisions.

## Maintained behavior

- The file dialog resolves cached media thumbnails using the freedesktop thumbnail-cache URI hash and prefers the largest available cache size.
- Nexus includes a display page for output arrangement, mode, refresh, scale, orientation, SDR/HDR colour mode, brightness, and saturation.
- Display changes are applied at runtime with a 15-second confirmation timer. They are reverted on timeout and written atomically to `~/.config/caelestia/hypr-monitor-generated.lua` only after **Keep** is selected.
- Nexus supports stable page routes while preserving the former control-center pane interface for rice keybind compatibility.
- Drawer and special-workspace handling tolerate monitor objects disappearing during hotplug or workspace transitions.

The rice configuration owns the include for `hypr-monitor-generated.lua`. A missing generated file must be valid, and baseline rules for known disconnected outputs must remain in the rice configuration until the display service has observed them.

## IPC routes

Open a top-level Nexus page with:

```sh
caelestia shell nexus openPage display
```

Top-level routes are `appearance`, `display`, `network`, `bluetooth`, `audio`, `updates`, `plugins`, `panels`, `apps`, `services`, `language`, and `about`.

The compatibility command `caelestia shell controlCenter openPane <pane>` accepts those routes plus `dashboard`, `taskbar`, `launcher`, and `notifications`.

Display automation is available through `caelestia shell display` with the `refresh`, `list`, `setHighestRefresh`, `setMain`, `move`, `keep`, and `revert` methods.

## Packaging and validation

The rice package recipe must pin this repository to a full commit and derive its package version from that revision. Do not package a moving branch or install unmanaged plugin libraries over package-owned paths.

Before advancing a shell revision, run a clean Release build, CTest, QML formatting and convention checks, C++ formatting checks, and QML linting with the build-tree imports. Validate the same commit in a target-native staging build before installation.
