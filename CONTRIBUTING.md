# Contributing

Thanks for contributing to `plasma-dynamic-island`.

## Before you open a change

- Search existing issues and pull requests first.
- Keep changes narrowly scoped. Separate cleanup from behavior changes.
- Open an issue before large UX changes, new dependencies, or compatibility
  changes that affect Plasma or Qt requirements.

## Local setup

### Requirements

- Qt 6.5+ (`Core`, `DBus`, `Qml`)
- CMake 3.21+
- A C++17 compiler
- KDE Plasma 6 runtime for manual testing
- `kpackagetool6`

### Build the bundled plugin

```bash
cmake -B plugin/build -S plugin -DCMAKE_BUILD_TYPE=Release
cmake --build plugin/build --parallel
```

### Install locally for manual testing

```bash
./install.sh
kquitapp6 plasmashell && kstart plasmashell
```

## Pull request expectations

- Explain the user-visible change and the reason for it.
- Include manual verification steps for UI, DBus, or Plasma behavior changes.
- Update docs when install steps, dependencies, or behavior change.
- Do not commit generated build output such as `plugin/build/`.

## Style notes

- Follow the existing code style in touched files.
- Prefer small, explicit QML components over broad refactors.
- Keep install and build paths user-local unless the change clearly requires
  system-wide installation support.

## Validation

At minimum, run the checks below before opening a pull request:

```bash
bash -n install.sh
cmake -B plugin/build -S plugin -DCMAKE_BUILD_TYPE=Release
cmake --build plugin/build --parallel
```

There is no comprehensive automated runtime test suite yet. If your change
affects notifications, media, OSD, or DBus integration, include the manual test
steps you used in the pull request description.
