# KittyMusicController 🐱🎵

A delightful macOS menu bar app for controlling music playback with a charming retro interface featuring an animated dancing kitty!

## Features

- 🎵 **Universal Music Control** - Works with any music app via system media keys
- 🎨 **Beautiful Retro UI** - Vinyl record animations, glass effects, and shimmer overlays
- 🐱 **Dancing Kitty Companion** - Animated GIF that dances along with your music
- ⚡ **Quick Access** - Lives in your menu bar for instant control
- 🎛️ **Transport Controls** - Play/pause, next, and previous track
- 🎯 **Direct App Launch** - Quick shortcuts to open Spotify, Apple Music, or YouTube Music
- 📊 **Playback Progress** - Visual progress ring around album artwork
- ✨ **Polish** - Smooth animations, hover effects, and attention to detail

## Architecture

### Project Structure

```
KittyMusicController/
├── App/                          # Application entry point
├── Models/                       # Data models and state
├── Services/                     # External integrations (AppleScript, etc.)
├── Coordinators/                 # Business logic and state management
├── UI/                          # SwiftUI views and components
│   ├── MenuBar/                 # Menu bar panel and content
│   └── Settings/                # Settings window
├── Utilities/                   # Helper functions and utilities
└── Previews/                    # SwiftUI preview providers
```

### Design Patterns

- **MVVM** - Models, Views, and ViewModels (Coordinators)
- **Protocol-Oriented** - Abstracted music control for flexibility
- **Observable Pattern** - SwiftUI's `@Published` and `ObservableObject`
- **Coordinator Pattern** - Centralized business logic in `PlaybackCoordinator`

### Key Components

#### Models
- **`AppState`** - Observable application state (playback, errors, etc.)
- **`PlaybackSnapshot`** - Immutable snapshot of current playback state
- **`PlaylistTrack`** - Representation of a music track
- **`MusicControlError`** - Typed errors for music control operations

#### Services
- **`MusicControlling`** - Protocol for music control operations
- **`MusicAppleScriptClient`** - AppleScript-based music control implementation

#### Coordinators
- **`PlaybackCoordinator`** - Manages playback state and user actions

#### UI Components
- **`MenuBarController`** - AppKit-based menu bar panel controller
- **`MenuBarContentView`** - Main SwiftUI view for the menu bar panel
- **`GlassEffectContainer`** - Reusable glass effect with shimmer animation
- **`SettingsView`** - Settings window interface

## Technical Highlights

### SwiftUI + AppKit Integration
The app seamlessly blends SwiftUI for UI and AppKit for system integration:
- `NSStatusItem` for menu bar presence
- `NSPanel` for the floating popup
- `NSHostingController` to host SwiftUI views
- Event monitors for click-outside-to-dismiss behavior

### Animations
- **Vinyl Rotation** - Continuous rotation using `TimelineView` and `rotationEffect`
- **GIF Animation** - Custom `NSViewRepresentable` for animated GIFs
- **Marquee Text** - Scrolling text for long song titles
- **Spring Animations** - Smooth, physics-based UI feedback
- **Shimmer Effects** - Elegant light sweeps across glass surfaces

### Media Control
Uses system media keys via AppleScript:
- **Key Code 16** - Play/Pause
- **Key Code 17** - Next Track
- **Key Code 18** - Previous Track

This approach works universally with any media app that responds to system media keys.

### Resource Loading
Flexible resource resolution system:
- Searches all app bundles
- Development fallback to project `Frameworks/` directory
- Works with both bundled and external resources

## Requirements

- macOS 13.0+ (Ventura or later)
- Xcode 15.0+
- Swift 5.9+

## Building

1. Clone the repository
2. Open `KittyMusicController.xcodeproj` in Xcode
3. Build and run (⌘R)

## Usage

1. **Launch the app** - A music note icon appears in your menu bar
2. **Click the icon** - Opens the control panel with:
   - Spinning vinyl album art (or kitty placeholder)
   - Dancing kitty companion
   - Song title, artist, and album info
   - Playback controls
   - App shortcuts
3. **Control playback** - Click play/pause, next, or previous
4. **Open music apps** - Use the app shortcut buttons
5. **Close the panel** - Click outside or press Escape

## Customization

### Adding More Music Apps

1. Add to `AppCommands.MediaShortcut`:
```swift
case myMusicApp

var bundleIdentifiers: [String] {
    case .myMusicApp: return ["com.example.mymusicapp"]
}
```

2. Add button to `MenuBarContentView`:
```swift
AppShortcutIconButton(
    symbol: "music.note",
    tint: Color.purple,
    helpText: "Open My Music App"
) {
    AppCommands.openMediaApp(.myMusicApp)
}
```

### Changing Colors

The UI uses a pink/purple gradient theme. Adjust in `MenuBarContentView`:
```swift
Color(red: 1.00, green: 0.52, blue: 0.83)  // Pink
Color(red: 0.84, green: 0.72, blue: 1.00)  // Purple
```

### Modifying Animations

- **Vinyl spin speed**: Change `/4.0` in `vinylAngle(at:)`
- **Marquee speed**: Adjust `22` in `startScrolling()`
- **Shimmer duration**: Modify `7` in `ShimmerSweepOverlay`

## Resources

Place these in your `Frameworks/` folder (or add to asset catalog):
- `dancing-kitty.gif` - Animated dancing cat GIF
- `kitty-no-music.png` - Static kitty icon for no playback state

## License

[Add your license here]

## Credits

Created with ❤️ and 🎵

---

**Enjoy your music with a dancing kitty companion!** 🐱✨
