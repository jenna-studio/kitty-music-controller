# KittyMusicController

KittyMusicController is a macOS menu bar music controller with a playful vinyl UI, animated kitty visuals, and quick launch buttons for common music apps.

## What It Does

- Lives in the macOS menu bar as a lightweight controller panel
- Shows current track metadata (title, artist, album)
- Displays album art in the center of the vinyl when available
- Uses kitty artwork as fallback when no artwork is available or nothing is playing
- Provides playback controls: previous, play/pause, next
- Includes quick-launch shortcuts for Spotify, Apple Music, and YouTube Music
- Displays the current audio output device with one-click switching to any available device
- Universal media key support works with any music app (Spotify, Apple Music, YouTube Music, etc.)

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

The project files are organized into logical folders:

```text
KittyMusicController/
├── App/
│   └── KittyMusicControllerApp.swift      # Main app entry point
├── Models/
│   ├── AppState.swift                     # Observable app state
│   └── PlaybackModels.swift               # Playback data models
├── Services/
│   └── MusicAppleScriptClient.swift       # Music control service
├── Coordinators/
│   └── PlaybackCoordinator.swift          # Business logic coordinator
├── Helpers/
│   └── AudioDeviceHelper.swift            # Audio device monitoring & control
├── UI/
│   ├── MenuBar/
│   │   ├── MenuBarContentView.swift       # Main UI with vinyl interface
│   │   ├── MenuBarController.swift        # Menu bar panel management
│   │   └── GlassEffectContainer.swift     # Glass effect UI component
│   └── Settings/
│       └── SettingsView.swift             # Settings interface
├── Utilities/
│   ├── AppCommands.swift                  # App launch utilities
│   └── PlaybackLogic.swift                # Playback utility functions
├── Previews/
│   └── Previews.swift                     # SwiftUI preview providers
├── Tests/
│   └── KittyMusicControllerTests.swift    # Unit tests
└── README.md                              # This file
```

## Key Components

- `App/KittyMusicControllerApp.swift`: Main app entry point and initialization
- `Models/AppState.swift`: Observable app-level state
- `Models/PlaybackModels.swift`: Playback snapshot and related models
- `Services/MusicAppleScriptClient.swift`: Media control + playback fetch implementation
- `Coordinators/PlaybackCoordinator.swift`: Orchestrates commands, refresh, and error handling
- `Helpers/AudioDeviceHelper.swift`: Monitors and controls audio output devices using CoreAudio
- `UI/MenuBar/MenuBarContentView.swift`: Primary menu panel UI and animation logic
- `UI/MenuBar/MenuBarController.swift`: Manages the menu bar status item and panel display
- `UI/MenuBar/GlassEffectContainer.swift`: Reusable glass effect component
- `UI/Settings/SettingsView.swift`: Settings window interface
- `Utilities/AppCommands.swift`: App-launch shortcuts and fallback resolution paths
- `Utilities/PlaybackLogic.swift`: Playback utility functions

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

- Playback and now-playing data are polled through the coordinator
- Music controls use system media keys for universal compatibility with all music apps
- AppleScript fallback ensures Spotify-specific control when media keys are unavailable
- Audio output device information is retrieved using CoreAudio APIs and automatically updates when the system output device changes
- Device switching affects the entire system, not just the music app
- UI previews are provided in `Previews/Previews.swift`
- Tests are in `Tests/KittyMusicControllerTests.swift`
- Comprehensive logging available in Console.app (filter for "MusicControl" or "Coordinator")

## Audio Device Control

The app includes real-time audio output device monitoring and switching:

- **AudioDeviceHelper** uses CoreAudio to detect and control the default output device
- The current device name is displayed as a clickable button below the playback controls
- Click the device button to open a popover menu showing all available audio output devices
- Select any device to instantly switch system audio output
- Changes to the system audio output device are automatically detected and reflected in the UI
- Smart device icons automatically detect device types (AirPods, headphones, speakers, etc.)

### Audio Device Features

- **Real-time monitoring**: Automatically detects when you plug/unplug devices
- **Universal switching**: Changes affect all apps system-wide
- **Visual feedback**: Current device highlighted with checkmark
- **Device detection**: Shows appropriate icons for AirPods, headphones, Bluetooth speakers, HDMI audio, etc.
- **Hover effects**: Interactive UI with smooth animations


