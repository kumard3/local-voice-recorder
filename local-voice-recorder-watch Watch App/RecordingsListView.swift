//
//  RecordingsListView.swift
//  local-voice-recorder-watch Watch App
//
//  Created by Kumar Deepanshu on 11/4/25.
//

import SwiftUI

struct RecordingsListView: View {
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var syncManager: SyncManager
    @ObservedObject var networkMonitor: NetworkMonitor
    @State private var rotationAngle: Double = 0
    @State private var rotationTimer: Timer?

    var body: some View {
        Group {
            if audioManager.recordings.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "waveform")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)

                    Text("No Recordings")
                        .font(.headline)
                        .foregroundColor(.gray)

                    Text("Tap the record button to start")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                VStack(spacing: 0) {
                    // Compact header aligned with navigation title
                    HStack(spacing: 6) {
                        // Sync button with animation
                        Button(action: {
                            print("━━━ UI: Manual sync button tapped")
                            Task {
                                await syncManager.manualSync()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption2)
                                .foregroundColor(networkMonitor.isWiFi ? .blue : .gray)
                                .rotationEffect(.degrees(rotationAngle))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(!networkMonitor.isWiFi || syncManager.isSyncing)
                        .onChange(of: syncManager.isSyncing) { isSyncing in
                            if isSyncing {
                                // Start rotation animation
                                rotationTimer?.invalidate()
                                rotationAngle = 0
                                rotationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                                    Task { @MainActor in
                                        withAnimation(.linear(duration: 0.05)) {
                                            rotationAngle += 18 // 18 degrees per frame (~360 degrees per second)
                                            if rotationAngle >= 360 {
                                                rotationAngle = 0
                                            }
                                        }
                                    }
                                }
                            } else {
                                // Stop rotation animation
                                rotationTimer?.invalidate()
                                rotationTimer = nil
                                withAnimation {
                                    rotationAngle = 0
                                }
                            }
                        }
                        .onDisappear {
                            rotationTimer?.invalidate()
                            rotationTimer = nil
                        }
                        
                        // WiFi indicator
                        Image(systemName: networkMonitor.isWiFi ? "wifi" : "wifi.slash")
                            .font(.caption2)
                            .foregroundColor(networkMonitor.isWiFi ? .green : .gray)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 2)
                    .padding(.bottom, 4)
                    
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(audioManager.recordings) { recording in
                                NavigationLink(destination: RecordingDetailView(
                                    recording: recording,
                                    audioManager: audioManager,
                                    syncManager: syncManager
                                )) {
                                    RecordingRowView(
                                        recording: recording,
                                        audioManager: audioManager,
                                        syncManager: syncManager
                                    )
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            audioManager.deleteRecording(recording)
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Recordings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    let audioManager = AudioManager()
    let networkMonitor = NetworkMonitor()
    let syncManager = SyncManager(networkMonitor: networkMonitor)

    NavigationView {
        RecordingsListView(
            audioManager: audioManager,
            syncManager: syncManager,
            networkMonitor: networkMonitor
        )
    }
}
