// PREVIEWS/Previews.swift
// This file contains SwiftUI preview providers
// Location: Previews/Previews.swift

import SwiftUI

#if DEBUG

@MainActor
private func makePreviewEnvironment() -> (AppState, PlaybackCoordinator) {
    let appState = AppState()

    let coordinator = PlaybackCoordinator(
        appState: appState,
        musicClient: PreviewMusicClient()
    )
    return (appState, coordinator)
}

@MainActor
private func makePreviewEnvironment(withPlayback: Bool, isPlaying: Bool = true, hasError: Bool = false) -> (AppState, PlaybackCoordinator) {
    let appState = AppState()
    
    if withPlayback {
        appState.playback = PlaybackSnapshot(
            trackID: "preview-1",
            title: "Sample Song",
            artists: ["Sample Artist", "Featured Artist"],
            album: "Sample Album",
            artworkURL: nil,
            isPlaying: isPlaying,
            source: .desktop,
            fetchedAt: Date(),
            playerPositionSeconds: 45,
            trackDurationSeconds: 210
        )
        appState.lastRefreshAt = Date()
    }
    
    if hasError {
        appState.errorMessage = "Music app is not running"
    }

    let coordinator = PlaybackCoordinator(
        appState: appState,
        musicClient: PreviewMusicClient()
    )
    return (appState, coordinator)
}

#Preview("Menu Bar Content - Playing") {
    @MainActor in
    let (appState, coordinator) = makePreviewEnvironment(withPlayback: true, isPlaying: true)
    MenuBarContentView(appState: appState, coordinator: coordinator)
}

#Preview("Menu Bar Content - Paused") {
    @MainActor in
    let (appState, coordinator) = makePreviewEnvironment(withPlayback: true, isPlaying: false)
    MenuBarContentView(appState: appState, coordinator: coordinator)
}

#Preview("Menu Bar Content - No Playback") {
    @MainActor in
    let (appState, coordinator) = makePreviewEnvironment(withPlayback: false)
    MenuBarContentView(appState: appState, coordinator: coordinator)
}

#Preview("Menu Bar Content - Error State") {
    @MainActor in
    let (appState, coordinator) = makePreviewEnvironment(withPlayback: false, hasError: true)
    MenuBarContentView(appState: appState, coordinator: coordinator)
}

#Preview("Settings") {
    @MainActor in
    let (appState, _) = makePreviewEnvironment()
    SettingsView(appState: appState)
}

// MARK: - Preview Helper

@MainActor
private final class PreviewMusicClient: MusicAppleScriptControlling {
    func playPause() async throws {
        print("Preview: Play/Pause toggled")
    }
    
    func nextTrack() async throws {
        print("Preview: Next track")
    }
    
    func previousTrack() async throws {
        print("Preview: Previous track")
    }
    
    func openMusicApp() throws {
        print("Preview: Opening music app")
    }
    
    func currentPlayback() async throws -> PlaybackSnapshot {
        return PlaybackSnapshot(
            trackID: "preview-1",
            title: "Preview Song",
            artists: ["Preview Artist"],
            album: "Preview Album",
            artworkURL: nil,
            isPlaying: true,
            source: .desktop,
            fetchedAt: Date(),
            playerPositionSeconds: 60,
            trackDurationSeconds: 180
        )
    }
}

#endif
