# plasma-dynamic-island

A KDE Plasma 6 panel plasmoid: a morphing capsule anchored to the top
panel that surfaces notifications, media, OSDs, progress jobs, and
timers with spring-based shape transitions.

## Install / upgrade

```bash
./install.sh
```

This builds the bundled `DBusSignalListener` C++ plugin (Qt6 Core+DBus+Qml,
~150 lines, see `plugin/`) into `~/.local/lib/qt6/qml/` and installs (or
upgrades) the plasmoid via `kpackagetool6`. Plasmashell must be restarted
once after the first install to load the plugin:

```bash
kquitapp6 plasmashell && kstart plasmashell
```

## Uninstall

```bash
kpackagetool6 -t Plasma/Applet --remove org.kde.plasma.dynamicisland
rm -rf ~/.local/lib/qt6/qml/org/kde/plasma/dynamicisland
```

## Build dependencies

- Qt 6.5+ (Core, DBus, Qml)
- CMake 3.21+
- a C++17 compiler
- KDE Frameworks 6 (for the plasmoid runtime; not linked by the plugin)
- `kpackagetool6`, `notify-send` (testing)
