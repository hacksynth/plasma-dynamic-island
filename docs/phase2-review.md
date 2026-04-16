# Phase 2 review

Static audit against the `phase-2` tag (commit `c4375be`). No code
executed, no plasmashell restart performed.

## 1. Scale

By source type (`wc -l`, repo root):

| Type     | Files | Lines |
|----------|-------|-------|
| QML      | 18    | 1971  |
| C++ (.cpp + .h)  | 2 | 379   |
| KCfg (XML)       | 1 | 20    |
| Shell (install.sh, dev.sh, bin/island-timer) | 3 | 184 |
| Markdown | 6     | 520   |

QML files by role (18 total):

- **Content** (5): `content/NotificationContent.qml` 92, `content/OsdContent.qml` 125, `content/MediaContent.qml` 152, `content/ProgressContent.qml` 98, `content/TimerContent.qml` 101
- **Source** (5): `NotificationSource.qml` 97, `OsdSource.qml` 128, `MediaSource.qml` 111, `ProgressSource.qml` 144, `TimerSource.qml` 275
- **Infrastructure** (6): `main.qml` 63, `IslandShell.qml` 32, `IslandCapsule.qml` 47, `IslandExpandedWindow.qml` 202, `IslandController.qml` 144, `Theme.qml` 38
- **Components** (1): `components/Marquee.qml` 116
- **Config** (1): `config/config.qml` 6

C++ plugin (h+cpp): **379 lines** total (`DBusSignalListener.h` 101, `DBusSignalListener.cpp` 278).

File tree + LOC:

```
plasma-dynamic-island/
├── contents/
│   ├── config/
│   │   ├── config.qml        6
│   │   └── main.xml         20
│   └── ui/
│       ├── main.qml         63
│       ├── Theme.qml        38
│       ├── IslandController.qml   144
│       ├── IslandShell.qml        32
│       ├── IslandCapsule.qml      47
│       ├── IslandExpandedWindow.qml  202
│       ├── NotificationSource.qml  97
│       ├── OsdSource.qml         128
│       ├── MediaSource.qml       111
│       ├── ProgressSource.qml    144
│       ├── TimerSource.qml       275
│       ├── qmldir              (singletons)
│       ├── components/
│       │   └── Marquee.qml       116
│       └── content/
│           ├── NotificationContent.qml  92
│           ├── OsdContent.qml          125
│           ├── MediaContent.qml        152
│           ├── ProgressContent.qml      98
│           └── TimerContent.qml        101
├── plugin/
│   ├── DBusSignalListener.h    101
│   ├── DBusSignalListener.cpp  278
│   ├── CMakeLists.txt
│   └── test.qml
├── bin/
│   └── island-timer           93
├── install.sh                 62
├── dev.sh                     29
└── docs/
    ├── phase3-design-reference.md  35
    └── phase2-review.md            (this file)
```

## 2. State machine completeness

`IslandController.stateDefs` (`IslandController.qml:8-16`):

| State | priority | persistent | defaultTimeout | width | expandedHeight |
|-------|----------|------------|----------------|-------|----------------|
| idle                 | 0 | true  | —    | 140 | 0  (uses `_panelSlotHeight`) |
| timer                | 1 | true  | —    | 200 | 52 |
| media                | 2 | true  | —    | 240 | 60 |
| progress             | 3 | true  | —    | 220 | 52 |
| notification         | 4 | false | 5000 | 200 | 56 |
| osd                  | 5 | false | 2000 | 130 | 40 |
| notificationCritical | 6 | false | 8000 | 220 | 64 |

Source → state mapping (grep of `IslandController.request(...)` in contents):

| State | Source | UI | Triggers observed |
|-------|--------|----|---|
| timer                | `TimerSource.qml:202`   | `content/TimerContent.qml`        | 1 request, 2 dismiss |
| media                | `MediaSource.qml:95`    | `content/MediaContent.qml`        | 1 request, 2 dismiss |
| progress             | `ProgressSource.qml:128`| `content/ProgressContent.qml`     | 1 request, 1 dismiss |
| osd                  | `OsdSource.qml:85,114`  | `content/OsdContent.qml`          | 2 requests (progress + text modes) |
| notification         | `NotificationSource.qml:81` (via `stateName` var) | `content/NotificationContent.qml` | 1 request (same site, priority-branched) |
| notificationCritical | `NotificationSource.qml:81` (via `stateName` var) | `content/NotificationContent.qml` (shared) | 1 request (same site) |
| idle                 | n/a (fallback only)     | — (capsule stays solid black)     | set by `_resolve()` when no slot/queue |

`IslandExpandedWindow._displayContentSource` switch (`IslandExpandedWindow.qml:31-45`) routes `notification` + `notificationCritical` to the same NotificationContent file; the other 4 have one route each. `idle` returns `""`.

Defined-but-untriggered: **none** (idle is intentionally only a fallback).

Triggered-but-undefined: **none** — grep of `request("…")` matches only defined stateDef keys.

## 3. D-Bus subscriptions and calls

Subscriptions (runtime):

| service | path | iface | signal(s) | subscriber |
|---|---|---|---|---|
| `org.kde.plasmashell` | `/org/kde/osdService` | `org.kde.osdService` | `osdProgress`, `osdText` | `OsdSource.qml:37-40` via `DBusSignalListener` |

Notification-manager and MPRIS use high-level KDE QML models (not raw D-Bus subscriptions from our code), but their underlying traffic:

| Indirect subscription | Access point |
|---|---|
| `org.freedesktop.Notifications` Notify server → model rows | `NM.Notifications { showNotifications: true }` in `NotificationSource.qml` |
| `org.kde.JobViewServer` / `org.kde.kuiserver` jobs → model rows | `NM.Notifications { showJobs: true }` in `ProgressSource.qml` |
| `org.mpris.MediaPlayer2.*` current player multiplex | `Mpris.Mpris2Model.currentPlayer` in `MediaSource.qml` |

Outbound method calls:

| service | path | iface | method | signature | caller |
|---|---|---|---|---|---|
| `org.freedesktop.Notifications` | `/org/freedesktop/Notifications` | `org.freedesktop.Notifications` | `Notify` | `susssasa{sv}i` → `u` | `TimerSource.qml:237` via `_bus.call()` |

No other outbound calls. `TimerSource` is the only code path that invokes `DBusSignalListener.call()`.

## 4. Cross-surface handoff correctness

`IslandExpandedWindow.qml`:

- β (pre-expand state cache + Dialog show): lines 106-113. `_displayState`/`_displayData` captured BEFORE the first `Qt.callLater`, so content survives later collapse-to-idle.
- γ (shell hide + behavior enable): lines 115-123, inside a single `Qt.callLater`. Sequence: `shellRef.opacity = 0`, enable `widthBehavior` and `heightBehavior`, start `deltaTimer` (16ms).
- δ (phase flip to "target"): `deltaTimer.onTriggered` at line 138 sets `_phase = "target"` and fires `contentFadeInTimer` (280ms). The capsule width/height bindings in lines 56-61 are `_phase === "target" ? targetW/H : idle` — so setting `_phase` is the single write that drives the spring.
- collapse: `_beginCollapse()` (126-131) fades content opacity to 0, `contentFadeOutTimer` (200ms, lines 151-161) enables behaviors and sets `_phase = "idle"`. `widthSpring.onRunningChanged` (180-195) is the finalizer: restores `shellRef.opacity = 1`, closes dialog, disables behaviors, clears `_displayState`/`_displayData`.

Verified properties:

- **opacity swap is inside one Qt.callLater**: ✓ (lines 115-123; shellRef opacity and behavior enables are in the same callback).
- **Behavior enable precedes binding change**: ✓ for δ (behaviors enabled at γ, target value set at δ one event-loop tick later); ✓ for collapse (behaviors enabled in `contentFadeOutTimer`, `_phase = "idle"` in the same handler but subsequent line — same frame, property-binding changes still picked up).
- **widthSpring finalizer is connected**: ✓ `Connections { target: widthSpring; function onRunningChanged()... }` at 180-195, guarded by `!IslandController.expanded` so it only fires on collapse.
- **No bypass writes to capsule.width/height**: grep of `\bwidth\s*=` and `\.width\s*=` under `contents/` returns zero matches. All sizing flows through `IslandController.targetWidth`/`Height` or the `_phase`-gated expression at `IslandExpandedWindow.qml:56-61`.

## 5. Known fragile points

| # | Fragility | Blocking Phase 3 / defer / ignore | Evidence |
|---|---|---|---|
| 1 | Timer missed-expiry path (plasmashell down while timer firing) not verified end-to-end | defer | Code path is `TimerSource.qml:264-271` (`Component.onCompleted` → `remaining <= 0` → `_expireTimer`). Plasmoidviewer restart in 5e-data showed the viewer strips unknown config keys, so persistence read was not demonstrable; real plasmashell not restarted during this session. |
| 2 | `notificationCritical` self-loop (timer-expiry → island re-picks its own notification) unverified in real plasmashell | defer | Plasmoidviewer's NotificationSource fails to register (`Failed to register Notification service on DBus` — `/tmp/pv.log`). In real plasmashell NotificationManager routes the Notify; architectural path is present but no runtime confirmation this session. |
| 3 | Progress pause/suspend visualization | defer | `ProgressSource.qml:7-11` records that V3.update({"suspended":…}) does NOT flip JobStateRole; only V2.setSuspended does. No real pausable-KIO job exercised. The `opacity: running ? 1.0 : 0.55` branch (`ProgressContent.qml:34`) is wired but never hit. |
| 4 | MPRIS source icon fallback when artUrl missing AND iconName empty | defer | `MediaContent.qml:58-63` falls back to `audio-x-generic`. No caller evidence that any real player omits both — but no explicit test recorded either. |
| 5 | Plasmoidviewer-specific: config Timer group wiped on startup | ignore | Viewer-specific bug. Not a bug in our plasmoid; real plasmashell reads schema correctly. |
| 6 | plasmoidviewer logs appear only with `QT_FORCE_STDERR_LOGGING=1` | ignore | Viewer quirk; dev-experience only. Documented in `dev.sh`. |
| 7 | Qt 6.11 pinned down to 6.10 in CI | ignore | `.github/workflows/ci.yml:26-33` — aqt 3.3.0 metadata gap, not a code issue. Will clear when aqt catches up. |
| 8 | XHR file read requires `QML_XHR_ALLOW_FILE_READ=1` | defer | Set by `install.sh:28` via Plasma env script and `systemctl --user`. If a user installs but does not relog or source env, TimerSource's file poll silently returns empty. No degradation log emitted. |
| 9 | `Theme.panelGap` defined but referenced zero times | ignore | Dead constant in Theme.qml:12 — unused since Phase 1 pivot. Safe to delete but harmless. |
| 10 | IslandShell has SpringAnimation Behaviors despite the architectural claim "IslandShell never animates" | ignore | `IslandShell.qml:17-30`. `IslandController.targetWidth/Height` do change, so the shell's capsule will spring, but it is `opacity: 0` during expand/collapse so it animates off-screen. Cost: one extra spring instance in parallel with the Dialog's. Not visible, not benchmarked. |

No `TODO`/`FIXME`/`XXX` in `contents/`. Only the Theme.qml shadow block was cleaned during sealing.

## 6. Dependency list

From imports (grep of `^import` in `contents/`) and `plugin/CMakeLists.txt`:

**Arch packages** required (inferred from imports, not verified against a fresh install):

| Package | Provides | Used by |
|---------|----------|---------|
| `plasma-desktop` / `plasma6-workspace` | `org.kde.plasma.plasmoid`, `org.kde.plasma.core`, NotificationManager, Mpris2 private modules, kpackagetool6 | main.qml, sources |
| `qt6-base` | QtQuick, QtCore, QtQuick.Layouts, DBus | all |
| `qt6-declarative` | QtQuick | all |
| `kirigami` / `kirigami2-5` for Plasma 6 equivalent | `org.kde.kirigami` | content/*, Marquee |
| `extra-cmake-modules` | ECM build | plugin |
| `cmake`, `ninja`, gcc | build tooling | plugin |
| `qt6-multimedia`? | **not verified** | MediaContent.qml uses `QtQuick.Effects` (MultiEffect) |
| `xdg-desktop-portal-kde` | freedesktop Notifications daemon | TimerSource expiry |

**Plasma-private QML modules** (may be bundled with plasma-workspace):

| Module | Used by |
|---|---|
| `org.kde.notificationmanager` | `NotificationSource.qml`, `ProgressSource.qml` |
| `org.kde.plasma.private.mpris` | `MediaSource.qml` |
| `org.kde.plasma.configuration` | `config/config.qml` |

**Locally-built plugin**:

- `org.kde.plasma.dynamicisland.dbussignal` → `~/.local/lib/qt6/qml/org/kde/plasma/dynamicisland/dbussignal/libdbussignallistenerplugin.so`
- Consumed by `OsdSource.qml`, `TimerSource.qml`, `plugin/test.qml`

**PATH** requirements:

- `~/.local/bin` on PATH so `island-timer` is callable. `install.sh:42-44` creates the symlink.
- `~/.local/lib/qt6/qml` on `QML2_IMPORT_PATH` for the D-Bus plugin. `install.sh:22-38` drops a Plasma env script and calls `systemctl --user set-environment`.
- `QML_XHR_ALLOW_FILE_READ=1` in the session env. `install.sh:27,37` sets both.

**Optional runtime helpers**:

- `mpv-mpris` or any MPRIS2 player (Elisa, Chromium with MPRIS, Spotify) to exercise media state.
- A KUiServer job producer (Dolphin copy, Discover install) to exercise progress state.
- `notify-send` to hand-trigger notification state.

## 7. Visual consistency

`Theme.qml` defines 19 readonly properties. Usage counts (grep `Theme\.<name>\b` + `UI\.Theme\.<name>\b`):

| Constant | Usages | Where |
|---|---|---|
| `islandBg` | 3 | IslandCapsule bg + Media/Progress marquee edgeColor |
| `idleWidth` | 2 | IslandController.targetWidth default + IslandExpandedWindow idle branch |
| `fallbackHeight` | 3 | IslandController defaults + main.qml panelThickness fallback |
| `panelGap` | **0** | **dead constant** |
| `springSpring` | 4 | IslandShell x2, IslandExpandedWindow x2 |
| `springDamping` | 4 | same |
| `springEpsilon` | 4 | same |
| `textPrimary` | 6 | 5 content files + MediaContent Canvas fill |
| `textSecondary` | 6 | 5 content files (incl. MediaContent pause bars x2) |
| `fillWhite` | 3 | Osd/Progress/Timer progress fill |
| `trackWhite` | 3 | Osd/Progress/Timer progress track |
| `summaryPixelSize` | 2 | Notification + Media |
| `bodyPixelSize` | 2 | Notification + Media |
| `osdTextPixelSize` | 1 | Osd text mode |
| `progressSummaryPixelSize` | 1 | Progress marquee |
| `countdownPixelSize` | 1 | Timer countdown |
| `pctLabelPixelSize` | 2 | Progress pct label + Timer label (shared font size) |
| `progressBarHeight` | 6 | Osd (2), Progress (2), Timer (2) |
| `contentBreathingRatio` | 2 | IslandCapsule left/right margins |

Remaining hardcoded values in `contents/`:

- `#f5f5f5` / `#a0a0a0` / `#30ffffff`: 0 outside Theme.qml (verified by grep).
- Per-component local numbers (intentional, not abstracted): MediaContent album-art 44×44, 8px artMask radius, Marquee 12px edge fade, progress opacity 0.55, Behavior durations (180ms Osd/Progress, 400ms Timer), icon sizes (18/22/24), play-triangle Canvas geometry.

Unused constant: `panelGap: 4` — vestigial from Phase 1.

## 8. Performance observations

Derived from code reading + logs; no bench.

**Per-second event rates (steady state)**:

- idle state: 0 events/s (all Timers not running; only poll loops).
- Timer active: **2 events/s** — file poll @ 500ms (2× XHR reads returning quickly-cached-identical content, no dispatch) + `ticker` @ 1000ms (one `IslandController.request("timer", {...})` per second).
- Media active, not playing changes: 0 events/s (signal-driven; no polling).
- Media changing tracks: bursty (up to 5 signal handlers fire in one frame per `MediaSource.qml:41-45`, coalesced by 50ms `_dispatchTimer` into one `_refresh()`; effectively ≤ 20 Hz upper bound).
- Progress active: `ProgressSource.qml:41-48` is model-driven, no polling; refresh fires per KIO `dataChanged` (typically 1-10 Hz from KIO speed).
- Notification arrival: 1 `_consumeRow()` call per row inserted.
- Timer file poll: 2 XHR reads/s regardless of whether a timer is active (`filePoll.start()` is called in `Component.onCompleted`; never stopped).

**FBO allocations (from `layer.enabled: true`)**:

- Exactly 1 layer in the codebase: `MediaContent.qml:40` — album-art rounded-corner mask, allocated when `artImage.status === Image.Ready`. Deallocated when image unloads.
- IslandCapsule / IslandShell: no `layer.enabled`. Morphing changes size but does not relayer.

**SpringAnimation concurrent instances**:

- IslandShell: width + height = 2 springs (always alive, may run invisibly since shell is opacity 0 during expand).
- IslandExpandedWindow capsule: width + height = 2 springs (gated by `widthBehavior.enabled` / `heightBehavior.enabled`).
- Theoretical max during expand/collapse: **4 concurrent springs**, 2 of which are driving invisible animation on the shell capsule.

**Timer instances at rest** (from `Timer { ... }` grep):

- IslandController: 1 (`_expiryTimer`, idle unless a temp state armed).
- IslandExpandedWindow: 3 (`deltaTimer`, `contentFadeInTimer`, `contentFadeOutTimer`; fire once per transition).
- ProgressSource: 1 (`_rescanTimer`, 30ms, single-shot on model churn).
- MediaSource: 1 (`_dispatchTimer`, 50ms, single-shot coalescer).
- TimerSource: 2 (`filePoll` 500ms repeat always running post-ready; `ticker` 1000ms repeat only while timer active).
- Marquee: 2 (start-hold / end-hold), per Marquee instance — there are up to 2 marquees on screen (Media + Progress).

**Memory**: Not evaluated: no RSS snapshot taken this session.

## 9. Extensibility cost (adding "battery-low" state)

Files that would need edits to add a new state:

| File | Change |
|---|---|
| `contents/ui/IslandController.qml` | add a row to `stateDefs` |
| `contents/ui/content/BatteryLowContent.qml` | new file |
| `contents/ui/BatterySource.qml` | new file |
| `contents/ui/main.qml` | instantiate `BatterySource { ... }` |
| `contents/ui/IslandExpandedWindow.qml` | add branch to `_displayContentSource` switch |
| `contents/ui/Theme.qml` | optional — only if new tokens needed |

Minimum: **5 files** (4 if Theme unchanged). This matches the established per-state pattern; no framework file beyond what's already factored is touched.

Cost indicator: low — `IslandController` and `IslandExpandedWindow` each take exactly one additive change. There is no second registration site (no map to keep in sync, no enum to extend in two places).

## 10. Phase 3 handoff — must-knows

1. **`outputOnly: true` architecture will need to be dropped.** Set in `IslandExpandedWindow.qml:11`. Currently the Dialog does not accept input events. Any interactive Phase 3 affordance (click, hover-pause auto-collapse, MPRIS seek, notification action buttons) requires flipping this to `false` AND reworking the collapse trigger — today the capsule auto-collapses when `IslandController.expanded` goes false, which doesn't happen while a mouse hovers.
2. **NotificationContent is shared between `notification` and `notificationCritical` states.** If Phase 3 introduces distinct critical chrome (red border, persistent dismiss button) the switch at `IslandExpandedWindow.qml:31-34` must split into two files. Data payload is already urgency-tagged in `NotificationSource.qml:86`.
3. **Dialog re-flow when content height changes at runtime is not supported.** `IslandExpandedWindow.qml:48-50` has a fixed `300x80` mainItem; the capsule is anchors.centerIn and its own width/height drives the spring. Tall variants (Phase 3 ~200px expanded media) require increasing the mainItem container AND potentially rebinding the Dialog's positioning.
4. **Spring params are shared across all states** (`Theme.qml:14-16`, referenced from both IslandShell and IslandExpandedWindow). Per-state animation tuning is explicitly warned against at `IslandExpandedWindow.qml:69-70` — if Phase 3 wants a different feel for interactive expansion vs passive state switches, this rule must be re-evaluated.
5. **The DBusSignalListener plugin is the only C++ and it's scoped narrowly** (subscribe + call). Any Phase 3 need for outbound binary data (seek position, MPRIS raw calls) may fit inside its existing `call()` — it already supports `a{sv}` maps, `as`, uint32, int64, etc., via the signature-coercion path.
6. **`QML_XHR_ALLOW_FILE_READ=1` is a session env var.** If Phase 3 removes TimerSource's file polling (in favor of, say, a D-Bus command channel), the install.sh and env-script lines can be deleted.
7. **Mpris2Model's `currentPlayer` selection is not controllable.** `MediaSource.qml:20` accepts whatever the multiplexer picks. Phase 3 "swipe between players" requires switching the source to iterate the full player list, not just `currentPlayer`.
8. **Persisted timer state uses Plasmoid.configuration Int (32-bit).** All timestamps are stored as unix seconds, not ms (`TimerSource.qml:9-10`). Breaks at year 2038 (~12 years). Acceptable for Phase 2; Phase 3 persistent features should respect the same constraint or extend the schema.
9. **Timer file protocol is content-hash deduped** (`TimerSource.qml:104-117`). Any non-CLI producer (automation, scripts) must either embed a nonce or accept that identical writes are silently dropped. Documented in README.md "Protocol details".
10. **Reviewable Phase 2 scope is frozen at git tag `phase-2` / commit `c4375be`.** Phase 3 branch work should reference this, not "latest main".

---

## TL;DR

5 states, 5 sources, 5 content files, 1 state machine, 1 cross-surface handoff, 379 lines of C++. Zero TODOs in contents, zero stale state transitions, zero bypass writes. Known fragilities are documented and all low-severity except "never actually restarted real plasmashell to prove end-to-end persistence". Theme has one dead constant (`panelGap`). Adding a state costs 4-5 file edits — architecture is clean. Phase 3 needs `outputOnly: false` and content-height flex first.
