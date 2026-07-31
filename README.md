# BoomBlocks

Android puzzle game: fit tetris-shaped earth blocks on an 8×8 board, clear lines, and collect gemstones.

## Features (v1)

- 8×8 board with drag-and-drop piece placement from a 3-piece tray
- Line clears on full rows and columns (no gravity)
- Gems on placed earth blocks — only scoring source; expire after 2 rounds
- Score formula: `lines cleared × gem value sum` (dynamite uses multiplier 1 when no lines)
- Renewable **Rope** (rotate a tray piece) and **Dynamite** (3×3 clear) with separate progress meters
- Difficulty ramp: harder pieces + slower item renewal
- Local save / continue + top-10 scoreboard with name prompt
- Adaptive Android launcher icons (layered foreground + cave background)
- Responsive UI: larger board on tablets; side-by-side board/tray in landscape

## Run

```bash
flutter pub get
flutter test
flutter run
```

Requires Flutter 3.32+ and an Android device/emulator.

## Stack

Flutter (Dart) · `shared_preferences` · Google Fonts (Fredoka / Nunito)
