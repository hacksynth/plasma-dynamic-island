# plasma-dynamic-island

`plasma-dynamic-island` is a KDE Plasma 6 panel plasmoid: a morphing capsule
anchored to the top panel that surfaces notifications, media, OSDs, progress
jobs, and timers with spring-based shape transitions.

## Status

This repository is functional but still early-stage. Expect iteration in the
QML behavior, install flow, and Plasma integration details while the project
stabilizes.

## Features

- Top-panel capsule UI with animated shape changes
- Notification, media, OSD, progress, and timer surfaces
- Bundled C++ DBus bridge exposed as a QML module
- User-local install flow for iterative development

## Install / upgrade

```bash
./install.sh
```

This script builds the bundled `DBusSignalListener` C++ plugin from `plugin/`
into `~/.local/lib/qt6/qml/` and installs or upgrades the plasmoid with
`kpackagetool6`.

Restart `plasmashell` after the first install or after plugin changes:

```bash
kquitapp6 plasmashell && kstart plasmashell
```

## Uninstall

```bash
kpackagetool6 -t Plasma/Applet --remove org.kde.plasma.dynamicisland
rm -rf ~/.local/lib/qt6/qml/org/kde/plasma/dynamicisland
```

## Development

### Requirements

- Qt 6.5+ (`Core`, `DBus`, `Qml`)
- CMake 3.21+
- A C++17 compiler
- KDE Frameworks 6 / Plasma 6 runtime for manual testing
- `kpackagetool6`

### Build only the plugin

```bash
cmake -B plugin/build -S plugin -DCMAKE_BUILD_TYPE=Release
cmake --build plugin/build --parallel
```

### Local install for manual testing

```bash
./install.sh
```

Useful manual checks:

- trigger a desktop notification
- verify media metadata appears when a player is active
- verify OSD updates react to brightness / volume changes

## Repository layout

- `contents/ui/`: plasmoid QML sources
- `plugin/`: bundled C++ QML plugin and CMake configuration
- `install.sh`: local build and install helper
- `metadata.json`: plasmoid metadata and versioning

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for local setup, validation steps, and
pull request expectations.

## Security

See [SECURITY.md](SECURITY.md) before reporting vulnerabilities.

## License

This project is licensed under `GPL-2.0-or-later`. See [LICENSE](LICENSE).
