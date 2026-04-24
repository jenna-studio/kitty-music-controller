// UI/Settings/SettingsView.swift
// This file contains the settings window view
// Location: UI/Settings/SettingsView.swift

import AppKit
import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        Form {
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
        .frame(width: 460)
    }
}
