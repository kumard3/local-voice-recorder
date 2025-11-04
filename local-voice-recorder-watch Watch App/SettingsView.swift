//
//  SettingsView.swift
//  local-voice-recorder-watch Watch App
//
//  Created by Kumar Deepanshu on 11/4/25.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var syncManager: SyncManager
    @ObservedObject var audioManager: AudioManager
    @AppStorage("autoDeleteAfterSync") private var autoDeleteAfterSync = false
    @State private var availableSpace: Int64?
    
    init(syncManager: SyncManager, audioManager: AudioManager) {
        self.syncManager = syncManager
        self.audioManager = audioManager
        // Initialize AppStorage with current value
        _autoDeleteAfterSync = AppStorage(wrappedValue: UserDefaults.standard.bool(forKey: "autoDeleteAfterSync"), "autoDeleteAfterSync")
    }

    var body: some View {
        List {
            // App Version Section
            Section {
                HStack {
                    Text("App Version")
                        .foregroundColor(.white)
                    Spacer()
                    Text(appVersion)
                        .foregroundColor(.gray)
                }
            }

            // Sync Settings Section
            Section(header: Text("Sync Settings")) {
                // Last Synced
                HStack {
                    Text("Last Synced")
                        .foregroundColor(.white)
                    Spacer()
                    Text(syncManager.lastSyncTimeString)
                        .foregroundColor(.gray)
                        .font(.caption)
                }

                // Auto-Delete After Sync Toggle
                Toggle(isOn: $autoDeleteAfterSync) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Delete After Sync")
                            .foregroundColor(.white)
                        Text("Remove files after successful upload")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .onChange(of: autoDeleteAfterSync) { newValue in
                    syncManager.setAutoDeleteAfterSync(newValue)
                }
            }

            // Storage Section
            Section(header: Text("Storage")) {
                // Available Space
                HStack {
                    Text("Available Space")
                        .foregroundColor(.white)
                    Spacer()
                    if let space = availableSpace {
                        Text(formatBytes(space))
                            .foregroundColor(.gray)
                    } else {
                        Text("Calculating...")
                            .foregroundColor(.gray)
                    }
                }

                // Total Storage Used
                HStack {
                    Text("Storage Used")
                        .foregroundColor(.white)
                    Spacer()
                    Text(syncManager.formatBytes(syncManager.getTotalStorageUsed()))
                        .foregroundColor(.gray)
                }
            }

            // Info Section
            Section {
                Text("Swipe left on recordings to delete")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            updateAvailableSpace()
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "\(version) (\(build))"
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func updateAvailableSpace() {
        Task { @MainActor in
            availableSpace = syncManager.getAvailableSpace()
        }
    }
}

#Preview {
    let networkMonitor = NetworkMonitor()
    let syncManager = SyncManager(networkMonitor: networkMonitor)
    let audioManager = AudioManager()
    
    NavigationView {
        SettingsView(syncManager: syncManager, audioManager: audioManager)
    }
}

