import SwiftUI

@main
struct KittyMusicControllerApp: App {
    @StateObject private var appState: AppState
    private let coordinator: PlaybackCoordinator
    private let menuBarController: MenuBarController
    private static let showInDockKey = "showInDock"
    
    init() {
        let appState = AppState()
        let coordinator = PlaybackCoordinator(
            appState: appState,
            musicClient: MusicAppleScriptClient()
        )
        _appState = StateObject(wrappedValue: appState)
        self.coordinator = coordinator
        self.menuBarController = MenuBarController(appState: appState, coordinator: coordinator)
        
        let showInDock = UserDefaults.standard.bool(forKey: Self.showInDockKey)
        DispatchQueue.main.async {
            if showInDock {
                NSApp.setActivationPolicy(.regular)
            } else {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }
    
    @MainActor
    private func setDockVisibility(_ visible: Bool) {
        UserDefaults.standard.set(visible, forKey: Self.showInDockKey)
        if visible {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    var body: some Scene {
        let _ = menuBarController

        Settings {
            SettingsView(appState: appState)
        }
    }
}
