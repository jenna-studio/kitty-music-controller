import SwiftUI

@main
struct KittyMusicControllerApp: App {
    @StateObject private var appState: AppState
    private let coordinator: PlaybackCoordinator
    private let menuBarController: MenuBarController

    init() {
        let appState = AppState()
        let coordinator = PlaybackCoordinator(
            appState: appState,
            musicClient: MusicAppleScriptClient()
        )
        _appState = StateObject(wrappedValue: appState)
        self.coordinator = coordinator
        self.menuBarController = MenuBarController(appState: appState, coordinator: coordinator)
    }

    var body: some Scene {
        let _ = menuBarController

        Settings {
            SettingsView(appState: appState)
        }
    }
}
