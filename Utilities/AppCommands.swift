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
        let config = NSWorkspace.OpenConfiguration()

        for bundleID in shortcut.bundleIdentifiers {
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                openApp(at: appURL, configuration: config)
                return
            }
        }

        for appPath in shortcut.knownAppPaths {
            if FileManager.default.fileExists(atPath: appPath) {
                openApp(at: URL(fileURLWithPath: appPath), configuration: config)
                return
            }
        }

        if let fallbackURL = shortcut.fallbackURL {
            NSWorkspace.shared.open(fallbackURL)
        }
    }

    private static func openApp(at appURL: URL, configuration: NSWorkspace.OpenConfiguration) {
        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration)
        NSApp.activate(ignoringOtherApps: true)
    }
}
