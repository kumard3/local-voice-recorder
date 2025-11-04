//
//  ContentView.swift
//  local-voice-recorder-watch Watch App
//
//  Created by Kumar Deepanshu on 11/4/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()
    @StateObject private var networkMonitor = NetworkMonitor()
    @StateObject private var syncManager: SyncManager

    init() {
        let monitor = NetworkMonitor()
        _networkMonitor = StateObject(wrappedValue: monitor)
        _syncManager = StateObject(wrappedValue: SyncManager(networkMonitor: monitor))
    }

    var body: some View {
        TabView {
            // Recording Tab
            NavigationView {
                RecordingView(audioManager: audioManager)
            }
            .tabItem {
                Label("Record", systemImage: "mic.circle.fill")
            }

            // Recordings List Tab
            NavigationView {
                RecordingsListView(
                    audioManager: audioManager,
                    syncManager: syncManager,
                    networkMonitor: networkMonitor
                )
            }
            .tabItem {
                Label("Recordings", systemImage: "list.bullet")
            }
            
            // Settings Tab
            NavigationView {
                SettingsView(syncManager: syncManager, audioManager: audioManager)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tabViewStyle(.page)
        .onAppear {
            // Connect sync manager to audio manager
            audioManager.setSyncManager(syncManager)
        }
    }
}

#Preview {
    ContentView()
}
