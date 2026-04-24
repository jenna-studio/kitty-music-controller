// UI/Settings/SettingsView.swift
// This file contains the settings window view
// Location: UI/Settings/SettingsView.swift

import AppKit
import SwiftUI
internal import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @AppStorage("showInDock") private var showInDock = false
    @State private var selectedSymbol: String = UserDefaults.standard.string(forKey: "statusIconSymbol") ?? "music.quarternote.3"
    @State private var useTemplateRendering: Bool = UserDefaults.standard.bool(forKey: "statusIconUseTemplate")
    @State private var hasCustomIcon: Bool = UserDefaults.standard.data(forKey: "statusIconCustomImageBookmark") != nil

    var body: some View {
        Form {
            Section("Appearance") {
                Toggle("Show in Dock", isOn: $showInDock)
                    .onChange(of: showInDock) { _, newValue in
                        setDockVisibility(newValue)
                    }
            }

            Section("Menu Bar Icon") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Choose an SF Symbol for the menu bar icon:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Picker("Symbol", selection: $selectedSymbol) {
                        HStack {
                            Image(systemName: "music.quarternote.3")
                            Text("Music Note (Default)")
                        }
                        .tag("music.quarternote.3")
                        
                        HStack {
                            Image(systemName: "music.note")
                            Text("Single Note")
                        }
                        .tag("music.note")
                        
                        HStack {
                            Image(systemName: "hifispeaker.fill")
                            Text("Speaker")
                        }
                        .tag("hifispeaker.fill")
                        
                        HStack {
                            Image(systemName: "headphones")
                            Text("Headphones")
                        }
                        .tag("headphones")
                        
                        HStack {
                            Image(systemName: "waveform")
                            Text("Waveform")
                        }
                        .tag("waveform")
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedSymbol) { _, newValue in
                        NotificationCenter.default.post(name: .init("StatusIconSymbolDidChange"), object: newValue)
                    }
                    
                    Toggle("Use template rendering (monochrome)", isOn: $useTemplateRendering)
                        .onChange(of: useTemplateRendering) { _, newValue in
                            NotificationCenter.default.post(name: .init("StatusIconUseTemplateDidChange"), object: newValue)
                        }
                    
                    Divider()
                    
                    Text("Or use a custom icon:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Button("Choose Custom Icon…") {
                            chooseCustomIcon()
                        }
                        
                        if hasCustomIcon {
                            Button("Clear Custom Icon") {
                                clearCustomIcon()
                            }
                            .foregroundStyle(.red)
                        }
                    }
                    
                    if hasCustomIcon {
                        Text("Custom icon is set (overrides SF Symbol)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Media Control") {
                Text("This app controls the active media session on your Mac using system media keys.")
                    .foregroundStyle(.secondary)
                Text("Use play/pause, previous, and next from the menu bar panel.")
                    .foregroundStyle(.secondary)
            }

            Section("App Actions") {
                Button("Quit App") {
                    NSApp.terminate(nil)
                }
            }

            if let error = appState.errorMessage {
                Section("Last Error") {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(20)
        .frame(width: 500)
    }
    
    private func setDockVisibility(_ visible: Bool) {
        if visible {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    private func chooseCustomIcon() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]
        panel.message = "Choose a custom icon for the menu bar"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                hasCustomIcon = true
                NotificationCenter.default.post(name: .init("StatusIconCustomImageDidChange"), object: url)
            }
        }
    }
    
    private func clearCustomIcon() {
        hasCustomIcon = false
        NotificationCenter.default.post(name: .init("StatusIconCustomImageDidChange"), object: nil)
    }
}
