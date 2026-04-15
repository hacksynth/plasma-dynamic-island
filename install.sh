#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "==> Building C++ plugin..."
cmake -B plugin/build -S plugin \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$HOME/.local"
cmake --build plugin/build --parallel
cmake --install plugin/build

echo "==> Installing plasmoid..."
if kpackagetool6 -t Plasma/Applet --list 2>/dev/null \
        | grep -q org.kde.plasma.dynamicisland; then
    kpackagetool6 -t Plasma/Applet --upgrade .
else
    kpackagetool6 -t Plasma/Applet --install .
fi

echo
echo "==> Done."
echo "    Plugin: \$HOME/.local/lib/qt6/qml/org/kde/plasma/dynamicisland/dbussignal/"
echo "    Plasmoid: \$HOME/.local/share/plasma/plasmoids/org.kde.plasma.dynamicisland/"
echo
echo "    Restart plasmashell to pick up plugin changes:"
echo "        kquitapp6 plasmashell && kstart plasmashell"
echo
echo "    If QML module is not found, ensure QML2_IMPORT_PATH includes"
echo "    \$HOME/.local/lib/qt6/qml — Plasma 6 normally picks this up"
echo "    via XDG_DATA_DIRS, but you may need to add it to your shell rc:"
echo "        export QML2_IMPORT_PATH=\"\$HOME/.local/lib/qt6/qml:\$QML2_IMPORT_PATH\""
