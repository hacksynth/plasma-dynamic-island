# plasma-dynamic-island

A KDE Plasma 6 panel plasmoid that mimics Apple's Dynamic Island: a morphing
capsule anchored to the top panel that surfaces notifications, media, OSDs,
progress jobs, and timers with spring-based shape transitions.

## Non-negotiables

- **Pure QML + JavaScript**, with one explicitly scoped C++ exception:
  a minimal `DBusSignalListener` plugin under `plugin/` that exposes
  arbitrary D-Bus signal subscription to QML. This exception exists
  because Plasma 6 + Qt 6 has no QML-native API for subscribing to
  arbitrary D-Bus signals, and the workarounds (shell-out to gdbus
  monitor, or per-source plasma-private QML types) are either too
  hacky or scale linearly with each new D-Bus source. The plugin's
  scope is strictly limited to signal forwarding — it must contain
  zero business logic. Any new C++ requires a separate hard-blocker
  review.
- **Qt 6.11, KF6, Plasma 6 only.** Never use Plasma 5 / Qt 5 idioms.
  Imports use the Plasma 6 style:
  `import org.kde.plasma.core as PlasmaCore`
  `import org.kde.plasma.plasmoid`
  `import QtQuick.Effects` (for MultiEffect)
- **60 fps minimum** on 4K. If an effect drops frames, cut it.
- **No `DropShadow`, no `FastBlur`.** Use `QtQuick.Effects.MultiEffect`
  (`shadowEnabled: true`, `blurEnabled: true`).
- **qmllint is CI.** After every `.qml` edit, run `qmllint <file>` and fix
  every warning before committing. On Arch the binary is `qmllint`
  (no `6` suffix), located at `/usr/lib/qt6/bin/qmllint`. It must be on PATH.
- **Small commits.** One feature / state / refactor per commit. Message
  format: `feat(media): spring transition on track change`.

## Environment (verified)

```
OS        : Arch Linux, kernel 6.19.11-zen1
CPU / RAM : AMD Ryzen 7 5700X, 32 GB
Session   : Wayland, KDE Plasma 6.6.4
Display   : DP-3, logical 1920x1080 @ Scale 2 (panel coords are 960 wide)
Qt        : 6.11.0
KF / ECM  : 6.25
Toolchain : gcc 15.2, cmake 4.3, ninja 1.13
Dev tools : plasmoidviewer (plasma-sdk), qmllint, qmlformat
D-Bus     : org.freedesktop.Notifications OK, org.kde.kuiserver OK
```

Consequence: default panel thickness on this setup is ~28-32 logical px.
The island must **read panel thickness at runtime**, never hardcode it.

## Architecture

```
plasma-dynamic-island/
├── metadata.json                 # Plasma 6 applet manifest
├── contents/
│   ├── config/
│   │   ├── main.xml              # KConfig schema
│   │   └── config.qml
│   ├── ui/
│   │   ├── main.qml              # CompactRepresentation anchor only
│   │   ├── IslandWindow.qml      # PlasmaCore.Dialog, the real island
│   │   ├── IslandShell.qml       # morphing rounded container + MultiEffect
│   │   ├── IslandController.qml  # singleton: state machine + priority queue
│   │   ├── Theme.qml             # singleton: colors, durations, sizes
│   │   ├── states/
│   │   │   ├── IdleState.qml
│   │   │   ├── NotificationState.qml
│   │   │   ├── MediaState.qml
│   │   │   ├── OsdState.qml
│   │   │   ├── ProgressState.qml
│   │   │   └── TimerState.qml
│   │   └── components/
│   │       ├── SpringBox.qml     # width/height spring wrapper
│   │       ├── Marquee.qml       # scrolling text for long titles
│   │       └── Glyph.qml         # icon with tint + pulse
│   └── code/
│       ├── PriorityQueue.js
│       └── DBusSources.js
└── README.md
```

### Why two windows (anchor + Dialog)

`compactRepresentation` lives inside the panel and is geometry-constrained.
A Dynamic Island needs to morph beyond the compact slot and draw its own
shadow without the panel clipping it. Solution: `main.qml` is a transparent
anchor Item sized to the island's *idle* footprint; the real island is a
`PlasmaCore.Dialog` (frameless, OnScreenDisplay type, stays-on-top) that
tracks the anchor's global position and draws below it.

### State machine

Priority (high -> low, temporary states preempt persistent ones):

```
OSD (2s)  >  Notification (5s)  >  Progress  >  Media  >  Timer  >  Idle
```

- Temporary states auto-expire via `Timer`, then the controller re-resolves
  the highest-priority persistent state and transitions to it.
- Concurrent temporary events are queued in `PriorityQueue.js`.
- Idle state: width 180, height = panelThickness, fully rounded (radius = h/2).
- Each state declares `targetWidth`, `targetHeight`, and a `Component`
  for its content. `IslandShell` binds to controller's target values and
  animates via `Behavior { SpringAnimation { spring: 3; damping: 0.28 } }`.

### Data sources (all D-Bus, zero C++)

| State        | Source                                                    |
|--------------|-----------------------------------------------------------|
| Notification | `org.freedesktop.Notifications` monitor (DBusMonitor)     |
| Media        | `org.mpris.MediaPlayer2.*` via `org.kde.plasma.private.mpris2` |
| OSD          | `org.kde.osdService` interception + PulseAudio watch      |
| Progress     | `org.kde.kuiserver` JobView                               |
| Timer        | local QML `Timer`, persisted via `plasmoid.configuration` |

All D-Bus wiring lives in `code/DBusSources.js` + per-state wrappers.
Never scatter `DBusInterface` literals across state files.

## Animation spec (Theme.qml constants)

- Shape morph: `SpringAnimation { spring: 3.0; damping: 0.28; epsilon: 0.01 }`
- Content fade: `NumberAnimation { duration: 180; easing: OutCubic }`
- Content slide: `240ms OutQuint`
- Hover expand: `160ms OutBack`, scale 1.0 -> 1.04
- **Never** linear easing. **Never** shape durations > 400 ms.

## Build / test loop

```bash
# first install
kpackagetool6 -t Plasma/Applet --install .

# iterate (fast, no plasmashell restart)
plasmoidviewer -a org.kde.plasma.dynamicisland

# upgrade after edits
kpackagetool6 -t Plasma/Applet --upgrade .

# lint (must be clean before commit)
find contents -name '*.qml' -exec qmllint {} +

# if the panel copy needs to refresh
kquitapp6 plasmashell && kstart plasmashell
```

## Coding rules for Claude Code

1. **Plan first.** For any change touching >1 file, output a plan and wait
   for approval before editing.
2. **One state at a time.** Never modify two state files in the same turn
   unless the change is a controller refactor.
3. **No inline D-Bus.** All D-Bus calls go through `code/DBusSources.js`.
4. **No magic numbers.** Durations, spring params, sizes -> `Theme.qml` or
   `config/main.xml`.
5. **Run qmllint** after every edit. Paste the output. Fix before continuing.
6. **Commit** after each green lint + manual verify in `plasmoidviewer`.
7. **Ask before adding dependencies.** Especially C++ or new QML modules.
8. **Respect Wayland.** Window positioning uses `PlasmaCore.Dialog`
   `visualParent` / `popupDirection`, never absolute screen coords.