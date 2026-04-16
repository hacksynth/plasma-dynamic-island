# Phase 3 design reference

User provided a third-party Android Dynamic Island implementation as
Phase 3 target reference. Key differences from current Phase 2 state:

## Idle state has content
- Left: shrunken album art (media indicator)
- Right: waveform / volume visualizer dots
- Currently we render idle as solid black; reference uses idle as
  a persistent compact info strip.

## Expanded state is taller and interactive
- ~200px expanded media (vs our 60px)
- 5 interactive buttons: app icon, prev, play/pause, next, like
- Full progress bar with elapsed/total time labels
- Background color extracted from album art (dominant color → black gradient)

## Interaction model
- Drops outputOnly architecture
- Click hit-testing on button regions
- Hover-pause logic (don't auto-collapse while pointer is over island)
- MPRIS control methods (Play/Pause/Next/Previous/Seek)

## Visual reference files
Place screenshots/video here when transitioning to Phase 3. Originals
were uploaded by user at end of Phase 2 step 5d-ui.

## Estimated effort
Roughly equivalent to Phase 2 in scope (~10-15 steps), broken into:
1. Drop outputOnly, add hover/click infrastructure
2. Idle state content (media-aware compact strip)
3. Expanded state taller variants per source type
4. Interactive buttons + MPRIS control wiring
5. Dominant color extraction (image processing in QML)
6. Seek bar drag interaction
