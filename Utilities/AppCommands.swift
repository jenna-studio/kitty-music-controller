// UTILITIES/AppCommands.swift
// This file contains app command utilities
// Location: Utilities/AppCommands.swift

import AppKit

enum AppCommands {
    enum MediaShortcut {
        case spotify
        case appleMusic
        case ytMusic

        var bundleIdentifiers: [String] {
            switch self {
            case .spotify:
                return ["com.spotify.client"]
            case .appleMusic:
                return ["com.apple.Music", "com.apple.iTunes"]
            case .ytMusic:
                return [
                    "com.google.Chrome.app.music.youtube.com",
                    "com.t4ils.ytmusic",
                    "com.github.th-ch.youtube-music",
                ]
            }
        }

        var fallbackURL: URL? {
            switch self {
            case .appleMusic:
                return URL(string: "music://")
            case .ytMusic:
                return URL(string: "https://music.youtube.com")
            default:
                return nil
            }
        }

        var knownAppPaths: [String] {
            switch self {
            case .appleMusic:
                return [
                    "/System/Applications/Music.app",
                    "/Applications/Music.app",
                    "/Applications/iTunes.app",
                ]
            default:
                return []
            }
        }
    }

    static func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    static func openMediaApp(_ shortcut: MediaShortcut) {
        NSLog("[AppCommands] Attempting to open: \(shortcut)")
        
        // Special handling for Apple Music - try URL scheme first
        if shortcut == .appleMusic {
            if let musicURL = URL(string: "music://") {
                NSLog("[AppCommands] Trying Apple Music URL scheme: music://")
                if NSWorkspace.shared.open(musicURL) {
                    NSLog("[AppCommands] Successfully opened Apple Music via URL scheme")
                    return
                } else {
                    NSLog("[AppCommands] URL scheme failed, trying other methods")
                }
            }
        }
        
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true // Ensure app activates

        // Try bundle identifiers first
        for bundleID in shortcut.bundleIdentifiers {
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                NSLog("[AppCommands] Found app via bundle ID: \(bundleID) at \(appURL.path)")
                openApp(at: appURL, configuration: config, name: "\(shortcut)")
                return
            } else {
                NSLog("[AppCommands] Bundle ID not found: \(bundleID)")
            }
        }

        // Try known paths
        for appPath in shortcut.knownAppPaths {
            if FileManager.default.fileExists(atPath: appPath) {
                NSLog("[AppCommands] Found app at path: \(appPath)")
                openApp(at: URL(fileURLWithPath: appPath), configuration: config, name: "\(shortcut)")
                return
            } else {
                NSLog("[AppCommands] Path not found: \(appPath)")
            }
        }

        // Try fallback URL (for YouTube Music)
        if let fallbackURL = shortcut.fallbackURL {
            NSLog("[AppCommands] Using fallback URL: \(fallbackURL)")
            NSWorkspace.shared.open(fallbackURL)
            return
        }
        
        NSLog("[AppCommands] ERROR: Could not open \(shortcut) - no method succeeded")
    }

    private static func openApp(at appURL: URL, configuration: NSWorkspace.OpenConfiguration, name: String) {
        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { app, error in
            if let error {
                NSLog("[AppCommands] ERROR opening \(name): \(error.localizedDescription)")
            } else if let app {
                NSLog("[AppCommands] Successfully opened \(name): \(app.localizedName ?? "Unknown")")
            } else {
                NSLog("[AppCommands] Opened \(name) but no app instance returned")
            }
        }
    }
}
