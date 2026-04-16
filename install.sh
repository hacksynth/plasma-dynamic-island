#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

PLUGIN_QML_DIR="$HOME/.local/lib/qt6/qml"

echo "==> Building C++ plugin..."
cmake -B plugin/build -S plugin \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$HOME/.local"
cmake --build plugin/build --parallel
cmake --install plugin/build

echo "==> Ensuring Plasma session sees the plugin's QML module path..."
# plasmashell does not automatically add ~/.local/lib/qt6/qml to its QML
# import path. Drop a Plasma startup script so future sessions pick it up,
# and inject it into the current systemd user environment so the next
# kstart plasmashell inherits it without requiring a logout.
ENV_DIR="$HOME/.config/plasma-workspace/env"
mkdir -p "$ENV_DIR"
cat >"$ENV_DIR/dynamic-island-qml-path.sh" <<EOF
#!/bin/sh
# Added by plasma-dynamic-island install.sh — make plasmashell load the
# DBusSignalListener QML plugin from the user-local prefix and allow
# TimerSource to read its control file via XMLHttpRequest file://.
export QML2_IMPORT_PATH="$PLUGIN_QML_DIR\${QML2_IMPORT_PATH:+:\$QML2_IMPORT_PATH}"
export QML_XHR_ALLOW_FILE_READ=1
EOF
chmod +x "$ENV_DIR/dynamic-island-qml-path.sh"

if command -v systemctl >/dev/null; then
    CURRENT_PATH=$(systemctl --user show-environment 2>/dev/null \
        | grep '^QML2_IMPORT_PATH=' | cut -d= -f2- || true)
    if [[ ":$CURRENT_PATH:" != *":$PLUGIN_QML_DIR:"* ]]; then
        NEW_PATH="$PLUGIN_QML_DIR${CURRENT_PATH:+:$CURRENT_PATH}"
        systemctl --user set-environment "QML2_IMPORT_PATH=$NEW_PATH"
        echo "    systemd --user QML2_IMPORT_PATH = $NEW_PATH"
    fi
    systemctl --user set-environment "QML_XHR_ALLOW_FILE_READ=1"
fi

echo "==> Installing plasmoid..."
if kpackagetool6 -t Plasma/Applet --list 2>/dev/null \
        | grep -q org.kde.plasma.dynamicisland; then
    kpackagetool6 -t Plasma/Applet --upgrade .
else
    kpackagetool6 -t Plasma/Applet --install .
fi

echo "==> Linking island-timer to ~/.local/bin..."
mkdir -p "$HOME/.local/bin"
ln -sf "$(pwd)/bin/island-timer" "$HOME/.local/bin/island-timer"

echo
echo "==> Done."
echo "    Plugin: $PLUGIN_QML_DIR/org/kde/plasma/dynamicisland/dbussignal/"
echo "    Plasmoid: \$HOME/.local/share/plasma/plasmoids/org.kde.plasma.dynamicisland/"
echo "    CLI:      \$HOME/.local/bin/island-timer (ensure ~/.local/bin is on PATH)"
echo
echo "    Restart plasmashell to pick up plugin changes:"
echo "        kquitapp6 plasmashell && kstart plasmashell"
