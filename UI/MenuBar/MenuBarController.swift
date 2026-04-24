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

        configureStatusItem()
        configurePanel()
        observeState()
    }

    @objc private func togglePanel() {
        if panel.isVisible {
            closePanel()
        } else {
            showPanel()
        }
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(togglePanel)
        button.sendAction(on: [.leftMouseUp])
        updateStatusIcon(isPlaying: appState.playback?.isPlaying == true)
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
    }

    private func updateStatusIcon(isPlaying: Bool) {
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "Kitty Music Controller")
        button.image?.isTemplate = true
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
