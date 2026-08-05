# AGENTS.md

This is ChrisBlackoutDev's personal fork of the Caelestia shell. It is coordinated with the personal Caelestia rice/bootstrap fork at `/home/kensa/.local/share/caelestia`.

This is not an AUR publishing workflow. The rice repo consumes this shell through a local PKGBUILD referenced by `local:bootstrap/pkgbuilds/caelestia-shell-fork` in `manifest.toml`.

## Safety Rules

- Run `git status --short --branch` before edits.
- Do not overwrite uncommitted user work.
- Keep upstream shell refresh work separate from local customizations.
- Inspect upstream before porting patches; skip local patches that upstream has already superseded.
- Do not change the rice PKGBUILD pin until the shell fork commit has built successfully.

## Build

Use this build before updating the rice package pin:

```sh
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build
```

## Coordination With Rice

After committing and pushing a shell fork change:

1. Update `/home/kensa/.local/share/caelestia/bootstrap/pkgbuilds/caelestia-shell-fork/PKGBUILD`.
2. Pin `source` and `GIT_REVISION` to the pushed shell commit.
3. Keep `pkgver` and `provides` correct for the packaged shell version.
4. Mirror the PKGBUILD to `/home/kensa/.local/src/caelestia-shell-fork/PKGBUILD` only if the standalone package worktree is being maintained.
5. Validate with `makepkg --printsrcinfo`.

Commit and push shell source changes before committing the rice package pin update.
