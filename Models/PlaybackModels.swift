// MODELS/PlaybackModels.swift
// This file contains all playback-related data models
// Moved from: SpotifyModels.swift → Models/PlaybackModels.swift
// Renamed: SpotifyControlError → MusicControlError

import Foundation

enum PlaybackSource: String, Codable, Sendable {
    case desktop
    case error
}

struct PlaybackSnapshot: Equatable, Sendable {
    var trackID: String
    var title: String
    var artists: [String]
    var album: String
    var artworkURL: URL?
    var isPlaying: Bool
    var source: PlaybackSource
    var fetchedAt: Date
    var playerPositionSeconds: Double?
    var trackDurationSeconds: Double?

    static let placeholder = PlaybackSnapshot(
        trackID: "placeholder",
        title: "Nothing playing",
        artists: ["Play media to begin"],
        album: "",
        artworkURL: nil,
        isPlaying: false,
        source: .error,
        fetchedAt: .distantPast,
        playerPositionSeconds: nil,
        trackDurationSeconds: nil
    )

    var artistLine: String {
        artists.joined(separator: ", ")
    }

    var progressFraction: Double {
        guard let playerPositionSeconds,
              let trackDurationSeconds,
              trackDurationSeconds > 0 else {
            return 0
        }
        return max(0, min(1, playerPositionSeconds / trackDurationSeconds))
    }
}

struct PlaylistTrack: Identifiable, Equatable, Sendable {
    let uri: String
    let id: String
    let name: String
    let artists: [String]
    let isPlayable: Bool
}

enum MusicControlError: Error, Equatable, LocalizedError, Sendable {
    case appMissing
    case appNotRunning
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .appMissing:
            return "Music app is not installed on this Mac."
        case .appNotRunning:
            return "Music app is not running. Open a music app first."
        case let .unknown(message):
            return "Unexpected error: \(message)"
        }
    }
}
