//
//  SettingsView.swift
//  VibeScaler
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("defaultSaveLocation") private var defaultSaveLocation: String = ""
    @AppStorage("defaultQuality") private var defaultQuality: String = "balanced"
    @AppStorage("autoRevealInFinder") private var autoRevealInFinder: Bool = true
    @AppStorage("useLocalByDefault") private var useLocalByDefault: Bool = true

    var body: some View {
        Form {
            // General Section
            Section {
                // Save Location
                HStack {
                    Text("Default Save Location")
                    Spacer()
                    Text(defaultSaveLocation.isEmpty ? "Downloads" : defaultSaveLocation)
                        .foregroundColor(.secondary)
                    Button("Choose...") {
                        chooseSaveLocation()
                    }
                }

                // Auto Reveal
                Toggle("Reveal in Finder after processing", isOn: $autoRevealInFinder)

                // Default to Local
                Toggle("Use local processing by default", isOn: $useLocalByDefault)

            } header: {
                Text("General")
            }

            // Quality Section
            Section {
                Picker("Default Quality", selection: $defaultQuality) {
                    Text("Fast").tag("fast")
                    Text("Balanced").tag("balanced")
                    Text("Maximum").tag("quality")
                }
                .pickerStyle(.segmented)

            } header: {
                Text("Quality")
            }

            // About Section
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }

                Link(destination: URL(string: "https://johnellison.com/vibescaler")!) {
                    HStack {
                        Text("Website")
                        Spacer()
                        Image(systemName: "arrow.up.forward.square")
                    }
                }

                Link(destination: URL(string: "https://johnellison.com/vibescaler/privacy")!) {
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "arrow.up.forward.square")
                    }
                }

                Link(destination: URL(string: "https://johnellison.com/vibescaler/support")!) {
                    HStack {
                        Text("Support")
                        Spacer()
                        Image(systemName: "arrow.up.forward.square")
                    }
                }

            } header: {
                Text("About")
            }

            // Data Section
            Section {
                Button("Clear Processing History") {
                    HistoryManager().clearHistory()
                }
                .foregroundColor(.red)

            } header: {
                Text("Data")
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 400)
    }

    private func chooseSaveLocation() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        panel.begin { response in
            if response == .OK, let url = panel.url {
                defaultSaveLocation = url.path
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
