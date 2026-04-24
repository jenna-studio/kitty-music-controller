// MODELS/AppState.swift
// This file contains the main observable app state
// Location: Models/AppState.swift

import Foundation
import Combine

@MainActor
final class AppState: ObservableObject {
    let objectWillChange: ObservableObjectPublisher
    
    @Published var playback: PlaybackSnapshot?
    @Published var isPerformingAction: Bool
    @Published var errorMessage: String?
    @Published var lastRefreshAt: Date?

    init() {
        self.objectWillChange = ObservableObjectPublisher()
        self.playback = nil
        self.isPerformingAction = false
        self.errorMessage = nil
        self.lastRefreshAt = nil
    }
}
