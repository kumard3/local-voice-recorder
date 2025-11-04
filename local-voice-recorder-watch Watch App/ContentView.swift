//
//  ContentView.swift
//  local-voice-recorder-watch Watch App
//
//  Created by Kumar Deepanshu on 11/4/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var audioManager = AudioManager()

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
                RecordingsListView(audioManager: audioManager)
            }
            .tabItem {
                Label("Recordings", systemImage: "list.bullet")
            }
        }
        .tabViewStyle(.page)
    }
}

#Preview {
    ContentView()
}
