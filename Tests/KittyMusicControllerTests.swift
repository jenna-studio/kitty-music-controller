// TESTS/KittyMusicControllerTests.swift
// This file contains unit tests
// Location: Tests/KittyMusicControllerTests.swift

#if canImport(XCTest)
import XCTest
@testable import KittyMusicController

@MainActor
final class KittyMusicControllerTests: XCTestCase {
    func testRandomSamplingReturnsDistinctTracksAndPreservesOrder() {
        let tracks = (1 ... 8).map {
            PlaylistTrack(
                uri: "track:\($0)",
                id: "\($0)",
                name: "Track \($0)",
                artists: ["Artist"],
                isPlayable: true
            )
        }
        var generator = SeededRandomNumberGenerator(seed: 42)

        let result = RandomTrackSampler.sample(tracks: tracks, desiredCount: 4, using: &generator)

        XCTAssertEqual(result.tracks.count, 4)
        XCTAssertEqual(Set(result.tracks.map(\.id)).count, 4)
        XCTAssertEqual(result.tracks.map(\.id), ["5", "3", "1", "7"])
    }

    func testRandomSamplingClampsToPlayableTracks() {
        let tracks = [
            PlaylistTrack(uri: "a", id: "a", name: "A", artists: ["A"], isPlayable: true),
            PlaylistTrack(uri: "b", id: "b", name: "B", artists: ["B"], isPlayable: false),
            PlaylistTrack(uri: "c", id: "c", name: "C", artists: ["C"], isPlayable: true),
        ]

        let result = RandomTrackSampler.sample(tracks: tracks, desiredCount: 5)

        XCTAssertEqual(result.clampedCount, 2)
        XCTAssertTrue(result.wasClamped)
        XCTAssertTrue(result.tracks.allSatisfy(\.isPlayable))
    }

    func testCoordinatorPreventsOverlappingRefreshes() async {
        let appState = AppState()
        let musicClient = SlowMusicClient()
        let coordinator = PlaybackCoordinator(appState: appState, musicClient: musicClient)

        async let first: Void = coordinator.refreshPlayback()
        async let second: Void = coordinator.refreshPlayback()
        _ = await (first, second)

        XCTAssertEqual(musicClient.currentPlaybackCallCount, 1)
    }
}

private final class SlowMusicClient: MusicAppleScriptControlling, @unchecked Sendable {
    private let queue = DispatchQueue(label: "SlowAppleScriptClient")
    private(set) var currentPlaybackCallCount = 0

    func playPause() async throws {}
    func nextTrack() async throws {}
    func previousTrack() async throws {}
    func openMusicApp() throws {}

    func currentPlayback() async throws -> PlaybackSnapshot {
        queue.sync {
            currentPlaybackCallCount += 1
        }
        try? await Task.sleep(for: .milliseconds(100))
        return PlaybackSnapshot(
            trackID: "1",
            title: "Track",
            artists: ["Artist"],
            album: "Album",
            artworkURL: nil,
            isPlaying: true,
            source: .desktop,
            fetchedAt: Date(),
            playerPositionSeconds: 30,
            trackDurationSeconds: 180
        )
    }
}
#endif
