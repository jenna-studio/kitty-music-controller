# KittyMusicController

KittyMusicController is a macOS menu bar music controller with a playful vinyl UI, animated kitty visuals, and quick launch buttons for common music apps.

## What It Does

- Lives in the macOS menu bar as a lightweight controller panel.
- Shows current track metadata (title, artist, album).
- Displays album art in the center of the vinyl when available.
- Uses kitty artwork as fallback when no artwork is available or nothing is playing.
- Provides playback controls: previous, play/pause, next.
- Includes quick-launch shortcuts for Spotify, Apple Music, and YouTube Music.

## Visual Playback Behavior

The UI is intentionally stateful and synchronized:

- **Playing state**
  - Vinyl spins.
  - Play button shows `pause`.
  - Stopper is on the vinyl.
- **Paused state**
  - Vinyl stops.
  - Play button shows `play`.
  - Stopper rotates right and moves away from the vinyl.

Floating decorative music notes appear only while playback is active.

## Project Structure

```text
KittyMusicController/
├── App/
├── Models/
├── Services/
├── Coordinators/
├── UI/
│   ├── MenuBar/
│   └── Settings/
├── Utilities/
├── Previews/
└── Tests/
```

## Key Components

- `Models/AppState.swift`: observable app-level state.
- `Models/PlaybackModels.swift`: playback snapshot and related models.
- `Services/MusicAppleScriptClient.swift`: media control + playback fetch implementation.
- `Coordinators/PlaybackCoordinator.swift`: orchestrates commands, refresh, and error handling.
- `UI/MenuBar/MenuBarContentView.swift`: primary menu panel UI and animation logic.
- `Utilities/AppCommands.swift`: app-launch shortcuts and fallback resolution paths.

## Requirements

- macOS
- Xcode (current)
- Swift 5+

## Build and Run

1. Open `KittyMusicController.xcodeproj` in Xcode.
2. Select the `KittyMusicController` scheme.
3. Build and run (`Cmd+R`).
4. Click the menu bar icon to open the controller panel.

## App Launch Shortcuts

Shortcuts are configured in `Utilities/AppCommands.swift`.

Current targets:

- Spotify
- Apple Music (bundle ID + known path fallbacks)
- YouTube Music variants

## Notes

- Playback and now-playing data are polled through the coordinator.
- UI previews are provided in `Previews/Previews.swift`.
- Existing tests are under `Tests/KittyMusicControllerTests.swift`.


