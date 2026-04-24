// SERVICES/MusicAppleScriptClient.swift
// This file handles AppleScript-based music control
// Moved from: SpotifyAppleScriptClient.swift → Services/MusicAppleScriptClient.swift
// Renamed: SpotifyAppleScriptControlling → MusicAppleScriptControlling

import AppKit
import Foundation

protocol MusicAppleScriptControlling: Sendable {
    func playPause() async throws
    func nextTrack() async throws
    func previousTrack() async throws
    func currentPlayback() async throws -> PlaybackSnapshot
    func openMusicApp() throws
}

struct MusicAppleScriptClient: MusicAppleScriptControlling {
    private let bundleIdentifier = "com.spotify.client"
    private let mediaKeyPlayPause: Int32 = 16
    private let mediaKeyNext: Int32 = 17
    private let mediaKeyPrevious: Int32 = 18

    func playPause() async throws {
        try sendSystemMediaKey(mediaKeyPlayPause)
    }

    func nextTrack() async throws {
        try sendSystemMediaKey(mediaKeyNext)
    }

    func previousTrack() async throws {
        try sendSystemMediaKey(mediaKeyPrevious)
    }

    func currentPlayback() async throws -> PlaybackSnapshot {
        let response = try run(script: """
        tell application "Spotify"
            set output to (id of current track) & "||" & (name of current track) & "||" & (artist of current track) & "||" & (album of current track) & "||" & (artwork url of current track) & "||" & (player state as text) & "||" & (player position as text) & "||" & (duration of current track as text)
            return output
        end tell
        """)

        let components = response.components(separatedBy: "||")
        guard components.count == 8 else {
            throw MusicControlError.unknown("Unexpected AppleScript payload.")
        }

        let isPlaying = components[5].lowercased().contains("playing")
        let artworkURL = URL(string: components[4])
        let playerPositionSeconds = Double(components[6])
        let trackDurationMilliseconds = Double(components[7])
        let trackDurationSeconds = trackDurationMilliseconds.map { $0 / 1000.0 }

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
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            throw MusicControlError.appMissing
        }
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { _, error in
            if let error {
                NSLog("Failed to open music app: \(error.localizedDescription)")
            }
        }
    }

    private func run(script: String) throws -> String {
        guard NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) != nil else {
            throw MusicControlError.appMissing
        }
        guard !NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).isEmpty else {
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
        try postMediaKeyEvent(keyType: keyType, isKeyDown: true)
        try postMediaKeyEvent(keyType: keyType, isKeyDown: false)
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
            throw MusicControlError.unknown("Failed to create media key event.")
        }

        guard let cgEvent = event.cgEvent else {
            throw MusicControlError.unknown("Failed to convert media key event.")
        }
        cgEvent.post(tap: .cghidEventTap)
    }
}
