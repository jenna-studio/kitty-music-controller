// UTILITIES/PlaybackLogic.swift
// This file contains playback utility functions
// Location: Utilities/PlaybackLogic.swift

import Foundation

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0x1234_5678_9ABC_DEF0 : seed
    }

    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }
}

struct RandomSelectionResult: Equatable {
    let tracks: [PlaylistTrack]
    let requestedCount: Int
    let clampedCount: Int

    var wasClamped: Bool {
        requestedCount != clampedCount
    }
}

enum RandomTrackSampler {
    static func sample<RNG: RandomNumberGenerator>(
        tracks: [PlaylistTrack],
        desiredCount: Int,
        using generator: inout RNG
    ) -> RandomSelectionResult {
        let playable = tracks.filter(\.isPlayable)
        let clampedCount = max(0, min(desiredCount, playable.count))
        let selected = Array(playable.shuffled(using: &generator).prefix(clampedCount))
        return RandomSelectionResult(tracks: selected, requestedCount: desiredCount, clampedCount: clampedCount)
    }

    static func sample(
        tracks: [PlaylistTrack],
        desiredCount: Int
    ) -> RandomSelectionResult {
        var generator = SystemRandomNumberGenerator()
        return sample(tracks: tracks, desiredCount: desiredCount, using: &generator)
    }
}

enum PlaybackSnapshotResolver {
    static func resolve(
        primary: PlaybackSnapshot?,
        secondary: PlaybackSnapshot?
    ) -> PlaybackSnapshot? {
        switch (primary, secondary) {
        case let (first?, second?):
            return first.fetchedAt >= second.fetchedAt ? first : second
        case let (first?, nil):
            return first
        case let (nil, second?):
            return second
        case (nil, nil):
            return nil
        }
    }
}
