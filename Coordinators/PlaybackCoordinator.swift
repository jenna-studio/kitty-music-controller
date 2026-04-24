// COORDINATORS/PlaybackCoordinator.swift
// This file contains business logic for playback coordination
// Updated: appleScriptClient → musicClient parameter

import Foundation

@MainActor
final class PlaybackCoordinator {
    private let appState: AppState
    private let musicClient: MusicAppleScriptControlling
    private var pollingTask: Task<Void, Never>?
    private var isRefreshingPlayback = false

    init(
        appState: AppState,
        musicClient: MusicAppleScriptControlling
    ) {
        self.appState = appState
        self.musicClient = musicClient
    }

    func menuDidOpen() {
        guard pollingTask == nil else { return }
        pollingTask = Task { [weak self] in
            await self?.pollLoop()
        }
    }

    func menuDidClose() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    func refreshPlayback() async {
        guard !isRefreshingPlayback else { return }
        isRefreshingPlayback = true
        defer { isRefreshingPlayback = false }

        do {
            let playback = try await musicClient.currentPlayback()
            appState.playback = playback
            appState.lastRefreshAt = Date()
            appState.errorMessage = nil
        } catch {
            if appState.playback == nil {
                appState.playback = PlaybackSnapshot.placeholder
            }
        }
    }

    func playPause() async {
        NSLog("[Coordinator] Play/Pause button pressed")
        await performControl { [self] in
            try await self.musicClient.playPause()
        }
    }

    func nextTrack() async {
        NSLog("[Coordinator] Next track button pressed")
        await performControl { [self] in
            try await self.musicClient.nextTrack()
        }
    }

    func previousTrack() async {
        NSLog("[Coordinator] Previous track button pressed")
        await performControl { [self] in
            try await self.musicClient.previousTrack()
        }
    }

    func openMusicApp() {
        do {
            try musicClient.openMusicApp()
            appState.errorMessage = nil
        } catch {
            appState.errorMessage = presentableMessage(for: error)
        }
    }

    private func pollLoop() async {
        await refreshPlayback()
        while !Task.isCancelled {
            await refreshPlayback()
            try? await Task.sleep(for: .seconds(1))
        }
    }

    private func performControl(_ action: @escaping () async throws -> Void) async {
        NSLog("[Coordinator] Starting control action")
        appState.isPerformingAction = true
        appState.errorMessage = nil
        defer { 
            appState.isPerformingAction = false
            NSLog("[Coordinator] Control action completed")
        }

        do {
            try await action()
            NSLog("[Coordinator] Action succeeded, refreshing playback")
            await refreshPlayback()
        } catch {
            NSLog("[Coordinator] Action failed: \(error.localizedDescription)")
            appState.errorMessage = presentableMessage(for: error)
        }
    }

    private func presentableMessage(for error: Error) -> String {
        if let musicError = error as? MusicControlError {
            return musicError.localizedDescription
        }
        return error.localizedDescription
    }
}
