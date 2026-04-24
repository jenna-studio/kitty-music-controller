// UI/MenuBar/MenuBarController.swift
// This file manages the menu bar panel and status item
// Location: UI/MenuBar/MenuBarController.swift

import AppKit
import Combine
import SwiftUI

@MainActor
final class MenuBarController {
    private let appState: AppState
    private let coordinator: PlaybackCoordinator
    private let statusItem: NSStatusItem
    private let panel: MenuBarPanel
    private let hostingController: NSHostingController<MenuBarContentView>

    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()

    private static let statusIconSymbolKey = "statusIconSymbol"
    private static let statusIconCustomImageBookmarkKey = "statusIconCustomImageBookmark"
    private static let statusIconUseTemplateKey = "statusIconUseTemplate"

    private var statusIconSymbol: String = UserDefaults.standard.string(forKey: MenuBarController.statusIconSymbolKey) ?? "music.quarternote.3"
    private var customIconURL: URL? = nil
    private var useTemplate: Bool = UserDefaults.standard.object(forKey: MenuBarController.statusIconUseTemplateKey) as? Bool ?? false

    init(appState: AppState, coordinator: PlaybackCoordinator) {
        self.appState = appState
        self.coordinator = coordinator

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        hostingController = NSHostingController(rootView: MenuBarContentView(appState: appState, coordinator: coordinator))
        panel = MenuBarPanel(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 300),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )

        configurePanel()
        loadCustomIconFromBookmark()
        configureStatusItem()
        observeState()
    }

    @objc private func togglePanel() {
        print("[MenuBarController] togglePanel called. Panel visible: \(panel.isVisible)")
        if panel.isVisible {
            closePanel()
        } else {
            showPanel()
        }
    }

    private func configureStatusItem() {
        print("[MenuBarController] Configuring status item. Button exists: \(statusItem.button != nil)")
        guard let button = statusItem.button else { 
            print("[MenuBarController] ERROR: Status item button is nil!")
            return 
        }
        button.target = self
        button.action = #selector(togglePanel)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        
        // Ensure button is enabled
        button.isEnabled = true
        
        updateStatusIcon(isPlaying: appState.playback?.isPlaying == true)
        print("[MenuBarController] Status item configured with action: \(String(describing: button.action))")
    }

    private func configurePanel() {
        panel.contentViewController = hostingController
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.isMovable = false
        panel.hidesOnDeactivate = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true

        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.backgroundColor = NSColor.clear.cgColor

    }

    private func observeState() {
        appState.$playback
            .map { $0?.isPlaying == true }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] isPlaying in
                self?.updateStatusIcon(isPlaying: isPlaying)
            }
            .store(in: &cancellables)

        NotificationCenter.default.addObserver(forName: .init("StatusIconSymbolDidChange"), object: nil, queue: .main) { [weak self] note in
            guard let symbol = note.object as? String else { return }
            Task { @MainActor [weak self] in
                self?.setStatusIconSymbol(symbol)
            }
        }
        NotificationCenter.default.addObserver(forName: .init("StatusIconCustomImageDidChange"), object: nil, queue: .main) { [weak self] note in
            let url = note.object as? URL
            Task { @MainActor [weak self] in
                self?.setCustomStatusIcon(url: url)
            }
        }
        NotificationCenter.default.addObserver(forName: .init("StatusIconUseTemplateDidChange"), object: nil, queue: .main) { [weak self] note in
            guard let template = note.object as? Bool else { return }
            Task { @MainActor [weak self] in
                self?.setUseTemplate(template)
            }
        }
        
        // Handle toggle panel notification from View menu
        NotificationCenter.default.addObserver(forName: .init("ToggleMenuBarPanel"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.togglePanel()
            }
        }
    }

    private func updateStatusIcon(isPlaying: Bool) {
        guard let button = statusItem.button else { 
            print("[MenuBarController] Cannot update icon - button is nil")
            return 
        }
        
        if let url = customIconURL, let image = NSImage(contentsOf: url) {
            button.image = image
            button.image?.isTemplate = useTemplate
            print("[MenuBarController] Updated to custom icon from: \(url.lastPathComponent)")
        } else {
            // Default to a colored SF Symbol
            let config = NSImage.SymbolConfiguration(pointSize: NSFont.systemFontSize, weight: .regular)
            let image = NSImage(systemSymbolName: statusIconSymbol, accessibilityDescription: "Kitty Music Controller")?.withSymbolConfiguration(config)
            button.image = image
            // Full color by default
            button.image?.isTemplate = false
            print("[MenuBarController] Updated to SF Symbol: \(statusIconSymbol)")
        }
    }

    func setStatusIconSymbol(_ symbolName: String) {
        statusIconSymbol = symbolName
        UserDefaults.standard.set(symbolName, forKey: Self.statusIconSymbolKey)
        updateStatusIcon(isPlaying: appState.playback?.isPlaying == true)
    }

    func setCustomStatusIcon(url: URL?) {
        customIconURL = url
        saveCustomIconBookmark(for: url)
        updateStatusIcon(isPlaying: appState.playback?.isPlaying == true)
    }

    func setUseTemplate(_ template: Bool) {
        useTemplate = template
        UserDefaults.standard.set(template, forKey: Self.statusIconUseTemplateKey)
        updateStatusIcon(isPlaying: appState.playback?.isPlaying == true)
    }

    private func loadCustomIconFromBookmark() {
        guard let data = UserDefaults.standard.data(forKey: Self.statusIconCustomImageBookmarkKey) else { customIconURL = nil; return }
        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: data, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
            if url.startAccessingSecurityScopedResource() {
                customIconURL = url
            } else {
                customIconURL = url
            }
        } catch {
            print("[MenuBarController] Failed to resolve custom icon bookmark: \(error)")
            customIconURL = nil
        }
    }

    private func saveCustomIconBookmark(for url: URL?) {
        if let url {
            do {
                let data = try url.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
                UserDefaults.standard.set(data, forKey: Self.statusIconCustomImageBookmarkKey)
            } catch {
                print("[MenuBarController] Failed to create bookmark: \(error)")
            }
        } else {
            UserDefaults.standard.removeObject(forKey: Self.statusIconCustomImageBookmarkKey)
        }
    }

    private func showPanel() {
        guard let button = statusItem.button,
              let buttonWindow = button.window,
              let screen = buttonWindow.screen ?? NSScreen.main
        else {
            return
        }

        hostingController.view.layoutSubtreeIfNeeded()
        let fittingSize = hostingController.view.fittingSize
        if fittingSize.width > 0, fittingSize.height > 0 {
            panel.setContentSize(fittingSize)
        }

        let buttonFrame = button.convert(button.bounds, to: nil)
        let buttonFrameInScreen = buttonWindow.convertToScreen(buttonFrame)
        let panelSize = panel.frame.size
        let visibleFrame = screen.visibleFrame

        var originX = buttonFrameInScreen.midX - (panelSize.width / 2)
        originX = max(visibleFrame.minX + 8, min(originX, visibleFrame.maxX - panelSize.width - 8))

        let originY = buttonFrameInScreen.minY - panelSize.height - 6
        panel.setFrameOrigin(NSPoint(x: originX, y: originY))

        startEventMonitors()
        panel.orderFront(nil)

        coordinator.menuDidOpen()
        Task {
            await coordinator.refreshPlayback()
        }
    }

    private func closePanel() {
        guard panel.isVisible else { return }
        panel.orderOut(nil)
        removeEventMonitors()
        coordinator.menuDidClose()
    }

    private func startEventMonitors() {
        removeEventMonitors()

        localEventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown, .keyDown]
        ) { [weak self] event in
            guard let self else { return event }

            if event.type == .keyDown, event.keyCode == 53 {
                self.closePanel()
                return nil
            }

            if event.window === self.panel {
                return event
            }

            self.closePanel()
            return event
        }

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            Task { @MainActor in
                self?.closePanel()
            }
        }
    }

    private func removeEventMonitors() {
        if let localEventMonitor {
            NSEvent.removeMonitor(localEventMonitor)
            self.localEventMonitor = nil
        }

        if let globalEventMonitor {
            NSEvent.removeMonitor(globalEventMonitor)
            self.globalEventMonitor = nil
        }
    }
}

private final class MenuBarPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
