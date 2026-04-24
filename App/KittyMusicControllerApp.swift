import SwiftUI

// MARK: - App Delegate to Retain Menu Bar Controller

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarController: MenuBarController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // MenuBarController is now set up after app state is initialized
    }
}

@main
struct KittyMusicControllerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState: AppState
    private let coordinator: PlaybackCoordinator
    private static let showInDockKey = "showInDock"
    
    init() {
        let appState = AppState()
        let coordinator = PlaybackCoordinator(
            appState: appState,
            musicClient: MusicAppleScriptClient()
        )
        _appState = StateObject(wrappedValue: appState)
        self.coordinator = coordinator
        
        // Set up menu bar controller via the app delegate to ensure it persists
        Task { @MainActor in
            let delegate = NSApplication.shared.delegate as? AppDelegate
            delegate?.menuBarController = MenuBarController(appState: appState, coordinator: coordinator)
        }
        
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
        Settings {
            SettingsView(appState: appState)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Kitty Music Controller") {
                    NSApp.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey.credits: NSAttributedString(
                                string: "A menu bar music controller for macOS",
                                attributes: [.font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)]
                            )
                        ]
                    )
                    NSApp.activate(ignoringOtherApps: true)
                }
            }

            CommandGroup(replacing: .appSettings) {
                Button("Settings…") {
                    AppCommands.openSettings()
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            CommandGroup(replacing: .newItem) {
                EmptyView()
            }

            // Optional: Add a debug/convenience command to open panel
            CommandMenu("View") {
                Button("Open Menu Bar Panel") {
                    // Call a method on menuBarController if we expose it
                    NotificationCenter.default.post(name: .init("ToggleMenuBarPanel"), object: nil)
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])
            }
        }
    }
}
