// SERVICES/MusicAppleScriptClient.swift
// This file handles AppleScript-based music control
// Moved from: SpotifyAppleScriptClient.swift → Services/MusicAppleScriptClient.swift
// Renamed: SpotifyAppleScriptControlling → MusicAppleScriptControlling

import AppKit
import Foundation
import MediaPlayer

protocol MusicAppleScriptControlling: Sendable {
    func playPause() async throws
    func nextTrack() async throws
    func previousTrack() async throws
    func currentPlayback() async throws -> PlaybackSnapshot
    func openMusicApp() throws
}

enum MusicApp: String {
    case spotify = "Spotify"
    case appleMusic = "Music"
    case youtubeMusic = "YouTube Music"
    
    var bundleIdentifiers: [String] {
        switch self {
        case .spotify:
            return ["com.spotify.client"]
        case .appleMusic:
            return ["com.apple.Music", "com.apple.iTunes"]
        case .youtubeMusic:
            return [
                "com.google.Chrome.app.music.youtube.com",
                "com.t4ils.ytmusic",
                "com.github.th-ch.youtube-music"
            ]
        }
    }
    
    var appleScriptName: String {
        switch self {
        case .spotify:
            return "Spotify"
        case .appleMusic:
            return "Music"
        case .youtubeMusic:
            return "Music" // YouTube Music uses Chrome or standalone apps, needs special handling
        }
    }
}

struct MusicAppleScriptClient: MusicAppleScriptControlling {
    private let mediaKeyPlayPause: Int32 = 16
    private let mediaKeyNext: Int32 = 17
    private let mediaKeyPrevious: Int32 = 18

    func playPause() async throws {
        // Try system media key first (works with all apps)
        do {
            try sendSystemMediaKey(mediaKeyPlayPause)
        } catch {
            // Fallback: try AppleScript for the detected app
            try await sendAppleScriptPlayPause()
        }
    }

    func nextTrack() async throws {
        // Try system media key first (works with all apps)
        do {
            try sendSystemMediaKey(mediaKeyNext)
        } catch {
            // Fallback: try AppleScript for the detected app
            try await sendAppleScriptNext()
        }
    }

    func previousTrack() async throws {
        // Try system media key first (works with all apps)
        do {
            try sendSystemMediaKey(mediaKeyPrevious)
        } catch {
            // Fallback: try AppleScript for the detected app
            try await sendAppleScriptPrevious()
        }
    }
    
    // MARK: - App Detection
    
    private func detectRunningMusicApp() -> MusicApp? {
        // Check in priority order: Spotify, Apple Music, YouTube Music
        for app in [MusicApp.spotify, .appleMusic, .youtubeMusic] {
            for bundleID in app.bundleIdentifiers {
                if !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty {
                    NSLog("[MusicControl] Detected running app: \(app.rawValue) (\(bundleID))")
                    return app
                }
            }
        }
        NSLog("[MusicControl] No music app detected")
        return nil
    }
    
    // MARK: - AppleScript Fallback Methods
    
    private func sendAppleScriptPlayPause() async throws {
        guard let app = detectRunningMusicApp() else {
            throw MusicControlError.appNotRunning
        }
        
        let script: String
        switch app {
        case .spotify:
            script = """
            tell application "Spotify"
                playpause
            end tell
            """
        case .appleMusic:
            script = """
            tell application "Music"
                playpause
            end tell
            """
        case .youtubeMusic:
            // YouTube Music doesn't have reliable AppleScript support
            // Media keys should work though
            throw MusicControlError.unknown("YouTube Music requires media keys")
        }
        
        _ = try runScript(script, for: app)
    }
    
    private func sendAppleScriptNext() async throws {
        guard let app = detectRunningMusicApp() else {
            throw MusicControlError.appNotRunning
        }
        
        let script: String
        switch app {
        case .spotify:
            script = """
            tell application "Spotify"
                next track
            end tell
            """
        case .appleMusic:
            script = """
            tell application "Music"
                next track
            end tell
            """
        case .youtubeMusic:
            throw MusicControlError.unknown("YouTube Music requires media keys")
        }
        
        _ = try runScript(script, for: app)
    }
    
    private func sendAppleScriptPrevious() async throws {
        guard let app = detectRunningMusicApp() else {
            throw MusicControlError.appNotRunning
        }
        
        let script: String
        switch app {
        case .spotify:
            script = """
            tell application "Spotify"
                previous track
            end tell
            """
        case .appleMusic:
            script = """
            tell application "Music"
                previous track
            end tell
            """
        case .youtubeMusic:
            throw MusicControlError.unknown("YouTube Music requires media keys")
        }
        
        _ = try runScript(script, for: app)
    }

    func currentPlayback() async throws -> PlaybackSnapshot {
        guard let app = detectRunningMusicApp() else {
            throw MusicControlError.appNotRunning
        }
        
        let script: String
        switch app {
        case .spotify:
            script = """
            tell application "Spotify"
                set output to (id of current track) & "||" & (name of current track) & "||" & (artist of current track) & "||" & (album of current track) & "||" & (artwork url of current track) & "||" & (player state as text) & "||" & (player position as text) & "||" & (duration of current track as text)
                return output
            end tell
            """
        case .appleMusic:
            script = """
            tell application "Music"
                if player state is stopped then
                    return "||Nothing Playing||||||stopped||0||0"
                end if
                set trackID to (database ID of current track as string)
                set trackName to (name of current track)
                set trackArtist to (artist of current track)
                set trackAlbum to (album of current track)
                set trackArtwork to ""
                set playerState to (player state as text)
                set playerPos to (player position as text)
                set trackDur to (duration of current track as text)
                set output to trackID & "||" & trackName & "||" & trackArtist & "||" & trackAlbum & "||" & trackArtwork & "||" & playerState & "||" & playerPos & "||" & trackDur
                return output
            end tell
            """
        case .youtubeMusic:
            // YouTube Music doesn't have native AppleScript support
            // Try to use macOS Now Playing info as fallback
            if let nowPlayingSnapshot = tryGetNowPlayingInfo() {
                return nowPlayingSnapshot
            }
            throw MusicControlError.unknown("YouTube Music playback info not available via AppleScript. Media controls still work!")
        }
        
        let response = try runScript(script, for: app)
        return try parsePlaybackResponse(response, from: app)
    }
    
    // MARK: - Now Playing Info (for apps without AppleScript support)
    
    private func tryGetNowPlayingInfo() -> PlaybackSnapshot? {
        // Try to get info from macOS Now Playing via distributed notifications
        // This works for browsers and other apps that publish media metadata
        #if os(macOS)
        NSLog("[MusicControl] Attempting to fetch Now Playing info for YouTube Music")
        
        // Try to get info from notification center's current media
        if let mediaInfo = getCurrentMediaInfo() {
            NSLog("[MusicControl] Successfully fetched Now Playing info")
            return mediaInfo
        }
        
        NSLog("[MusicControl] No Now Playing info available - returning placeholder")
        // Return a placeholder that indicates controls work
        return PlaybackSnapshot(
            trackID: "youtube-music",
            title: "YouTube Music",
            artists: ["Media controls available"],
            album: "Playing in browser",
            artworkURL: nil,
            isPlaying: true,
            source: .desktop,
            fetchedAt: Date(),
            playerPositionSeconds: nil,
            trackDurationSeconds: nil
        )
        #endif
    }
    
    private func getCurrentMediaInfo() -> PlaybackSnapshot? {
        // On macOS, we can try to get info from MRMediaRemoteGetNowPlayingInfo
        // This is a private API but widely used
        // Alternatively, we can use AppleScript to query Chrome's tab title
        
        // Try to get Chrome tab info if YouTube Music is in Chrome
        if let chromeInfo = tryGetChromeTabInfo() {
            return chromeInfo
        }
        
        // Try standalone YouTube Music apps
        if let standaloneInfo = tryGetStandaloneYouTubeMusicInfo() {
            return standaloneInfo
        }
        
        return nil
    }
    
    private func tryGetChromeTabInfo() -> PlaybackSnapshot? {
        // Check if Chrome is running with YouTube Music
        let chromeRunning = !NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.google.Chrome"
        ).isEmpty
        
        guard chromeRunning else {
            return nil
        }
        
        // Use AppleScript to get active tab title from Chrome
        let script = """
        tell application "Google Chrome"
            if (count of windows) > 0 then
                set activeTab to active tab of front window
                set tabTitle to title of activeTab
                set tabURL to URL of activeTab
                if tabURL contains "music.youtube.com" then
                    return tabTitle
                end if
            end if
            return ""
        end tell
        """
        
        do {
            var errorInfo: NSDictionary?
            guard let appleScript = NSAppleScript(source: script) else {
                return nil
            }
            let result = appleScript.executeAndReturnError(&errorInfo)
            
            if let errorInfo {
                NSLog("[MusicControl] Chrome tab query error: \(errorInfo)")
                return nil
            }
            
            if let tabTitle = result.stringValue, !tabTitle.isEmpty {
                // Parse title - YouTube Music format is usually "Song Name - Artist - YouTube Music"
                return parseYouTubeMusicTitle(tabTitle)
            }
        } catch {
            NSLog("[MusicControl] Error querying Chrome: \(error)")
        }
        
        return nil
    }
    
    private func tryGetStandaloneYouTubeMusicInfo() -> PlaybackSnapshot? {
        // Try T4ils YouTube Music app
        for bundleID in ["com.t4ils.ytmusic", "com.github.th-ch.youtube-music"] {
            let running = !NSRunningApplication.runningApplications(
                withBundleIdentifier: bundleID
            ).isEmpty
            
            if running {
                // Try to get window title via Accessibility API
                if let windowTitle = getWindowTitle(for: bundleID) {
                    return parseYouTubeMusicTitle(windowTitle)
                }
            }
        }
        
        return nil
    }
    
    private func getWindowTitle(for bundleID: String) -> String? {
        // Get the frontmost window title for the app
        let script = """
        tell application "System Events"
            set appName to name of first application process whose bundle identifier is "\(bundleID)"
            tell application process appName
                if (count of windows) > 0 then
                    return name of front window
                end if
            end tell
        end tell
        """
        
        var errorInfo: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else {
            return nil
        }
        let result = appleScript.executeAndReturnError(&errorInfo)
        
        if errorInfo != nil {
            return nil
        }
        
        return result.stringValue
    }
    
    private func parseYouTubeMusicTitle(_ title: String) -> PlaybackSnapshot {
        // YouTube Music title formats we handle:
        // 1. "Song Name - Artist - YouTube Music"
        // 2. "Song Name - Artist"
        // 3. "Artist - Topic" (for music videos)
        // 4. "Song Name" (fallback)
        
        var rawTitle = title.trimmingCharacters(in: .whitespaces)
        
        // Remove " - YouTube Music" suffix if present
        if rawTitle.hasSuffix(" - YouTube Music") {
            rawTitle = String(rawTitle.dropLast(" - YouTube Music".count))
        }
        
        // Remove "- Topic" suffix (YouTube auto-generated artist channels)
        if rawTitle.hasSuffix(" - Topic") {
            rawTitle = String(rawTitle.dropLast(" - Topic".count))
        }
        
        // Split by " - " to separate song and artist
        let components = rawTitle.components(separatedBy: " - ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        let songTitle: String
        let artistName: String
        let albumName: String
        
        if components.count >= 2 {
            // Format: "Song - Artist" or "Song - Artist - Album"
            songTitle = components[0]
            artistName = components[1]
            
            // If there are more components, use them as album info
            if components.count > 2 {
                albumName = components[2...].joined(separator: " - ")
            } else {
                albumName = "YouTube Music"
            }
        } else if components.count == 1 {
            // Only one component - could be just song title or just artist
            // Check if it looks like an artist name (contains "VEVO", "Official", etc.)
            let singleComponent = components[0]
            if singleComponent.contains("VEVO") || 
               singleComponent.contains("Official") ||
               singleComponent.contains(" - ") {
                // Likely an artist or channel name
                songTitle = "YouTube Music"
                artistName = singleComponent
            } else {
                // Likely a song title
                songTitle = singleComponent
                artistName = "Unknown Artist"
            }
            albumName = "YouTube Music"
        } else {
            // Empty or invalid
            songTitle = "YouTube Music"
            artistName = "Unknown"
            albumName = "YouTube Music"
        }
        
        NSLog("[MusicControl] Parsed YouTube Music - Title: '\(songTitle)' | Artist: '\(artistName)' | Album: '\(albumName)'")
        
        return PlaybackSnapshot(
            trackID: "youtube-\(songTitle.hashValue)-\(artistName.hashValue)",
            title: songTitle,
            artists: [artistName],
            album: albumName,
            artworkURL: nil,
            isPlaying: true,
            source: .desktop,
            fetchedAt: Date(),
            playerPositionSeconds: nil,
            trackDurationSeconds: nil
        )
    }
    
    private func parsePlaybackResponse(_ response: String, from app: MusicApp) throws -> PlaybackSnapshot {
        let components = response.components(separatedBy: "||")
        guard components.count == 8 else {
            throw MusicControlError.unknown("Unexpected AppleScript payload: \(components.count) components")
        }

        let isPlaying = components[5].lowercased().contains("playing")
        
        // Handle artwork URL differently per app
        let artworkURL: URL?
        switch app {
        case .spotify:
            artworkURL = URL(string: components[4])
        case .appleMusic:
            // Apple Music doesn't provide artwork URL via AppleScript
            artworkURL = nil
        case .youtubeMusic:
            artworkURL = nil
        }
        
        let playerPositionSeconds = Double(components[6])
        
        // Handle duration differently per app
        let trackDurationSeconds: Double?
        switch app {
        case .spotify:
            // Spotify returns duration in milliseconds
            if let durationMs = Double(components[7]) {
                trackDurationSeconds = durationMs / 1000.0
            } else {
                trackDurationSeconds = nil
            }
        case .appleMusic, .youtubeMusic:
            // Apple Music returns duration in seconds
            trackDurationSeconds = Double(components[7])
        }

        return PlaybackSnapshot(
            trackID: components[0],
            title: components[1],
            artists: [components[2]],
            album: components[3],
            artworkURL: artworkURL,
            isPlaying: isPlaying,
            source: .desktop,
            fetchedAt: Date(),
            playerPositionSeconds: playerPositionSeconds,
            trackDurationSeconds: trackDurationSeconds
        )
    }

    func openMusicApp() throws {
        // Try to open any detected music app, with priority order
        for app in [MusicApp.spotify, .appleMusic, .youtubeMusic] {
            for bundleID in app.bundleIdentifiers {
                if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                    NSLog("[MusicControl] Opening \(app.rawValue)")
                    let configuration = NSWorkspace.OpenConfiguration()
                    NSWorkspace.shared.openApplication(at: url, configuration: configuration) { _, error in
                        if let error {
                            NSLog("Failed to open \(app.rawValue): \(error.localizedDescription)")
                        }
                    }
                    return
                }
            }
        }
        throw MusicControlError.appMissing
    }

    private func runScript(_ script: String, for app: MusicApp) throws -> String {
        // Check if app is installed
        var foundBundleID: String?
        for bundleID in app.bundleIdentifiers {
            if NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) != nil {
                foundBundleID = bundleID
                break
            }
        }
        
        guard foundBundleID != nil else {
            throw MusicControlError.appMissing
        }
        
        // Check if app is running
        var isRunning = false
        for bundleID in app.bundleIdentifiers {
            if !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty {
                isRunning = true
                break
            }
        }
        
        guard isRunning else {
            throw MusicControlError.appNotRunning
        }
        
        var errorInfo: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else {
            throw MusicControlError.unknown("Failed to create AppleScript.")
        }
        let result = appleScript.executeAndReturnError(&errorInfo)
        if let errorInfo {
            throw MusicControlError.unknown(errorInfo.description)
        }
        return result.stringValue ?? ""
    }

    private func sendSystemMediaKey(_ keyType: Int32) throws {
        // Post key down and key up for a system-defined media key event.
        // This simulates pressing the media keys on your keyboard
        NSLog("[MusicControl] Sending system media key: \(keyType)")
        try postMediaKeyEvent(keyType: keyType, isKeyDown: true)
        try postMediaKeyEvent(keyType: keyType, isKeyDown: false)
        NSLog("[MusicControl] Successfully sent media key")
    }

    private func postMediaKeyEvent(keyType: Int32, isKeyDown: Bool) throws {
        let state: Int32 = isKeyDown ? 0xA : 0xB
        let flags: UInt = isKeyDown ? 0xA00 : 0xB00
        let data1 = Int((keyType << 16) | (state << 8))

        guard let event = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: flags),
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: data1,
            data2: -1
        ) else {
            NSLog("[MusicControl] ERROR: Failed to create media key event")
            throw MusicControlError.unknown("Failed to create media key event.")
        }

        guard let cgEvent = event.cgEvent else {
            NSLog("[MusicControl] ERROR: Failed to convert to CGEvent")
            throw MusicControlError.unknown("Failed to convert media key event.")
        }
        
        // Post the event to the HID event tap
        cgEvent.post(tap: .cghidEventTap)
    }
}
