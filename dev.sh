#!/usr/bin/env bash
# Fast dev iteration loop. Avoids restarting the real plasmashell.
#
# Usage:
#   ./dev.sh           — upgrade plasmoid, restart plasmoidviewer
#   ./dev.sh plugin    — same, but also rebuild the C++ plugin first

set -euo pipefail
cd "$(dirname "$0")"

if [[ "${1:-}" == "plugin" ]]; then
    echo "==> Rebuilding plugin..."
    cmake --build plugin/build --parallel
    cmake --install plugin/build
fi

echo "==> Upgrading plasmoid..."
kpackagetool6 -t Plasma/Applet --upgrade .

echo "==> Restarting plasmoidviewer..."
pkill -9 plasmoidviewer 2>/dev/null || true
sleep 0.3
plasmoidviewer -a org.kde.plasma.dynamicisland \
    -c org.kde.panel -f horizontal -l topedge \
    -s 800x80 >/tmp/plasmoidviewer.log 2>&1 &

echo "==> Done. Logs at /tmp/plasmoidviewer.log"
echo "==> To watch ctrl/source/handoff logs:"
echo "    tail -f /tmp/plasmoidviewer.log | grep -E '\[ctrl\]|\[notif\]|\[osd\]|\[media\]|\[progress\]|\[handoff\]'"
