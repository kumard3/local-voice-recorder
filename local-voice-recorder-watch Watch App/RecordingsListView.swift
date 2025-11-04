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
                    // Sync status header
                    VStack(spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: networkMonitor.isWiFi ? "wifi" : "wifi.slash")
                                .font(.caption)
                                .foregroundColor(networkMonitor.isWiFi ? .green : .gray)

                            Text(networkMonitor.isWiFi ? "WiFi Connected" : "No WiFi")
                                .font(.caption2)
                                .foregroundColor(.gray)

                            Spacer()

                            if syncManager.isSyncing {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Button(action: {
                                    Task {
                                        await syncManager.manualSync()
                                    }
                                }) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.caption)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(!networkMonitor.isWiFi)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)

                        // Storage info
                        HStack(spacing: 4) {
                            Text("\(syncManager.getPendingSyncCount()) pending")
                                .font(.caption2)
                                .foregroundColor(.orange)

                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.gray)

                            Text(syncManager.formatBytes(syncManager.getTotalStorageUsed()))
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 4)
                    }
                    .background(Color.black.opacity(0.2))

                    // Recordings list
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(audioManager.recordings) { recording in
                                RecordingRowView(
                                    recording: recording,
                                    audioManager: audioManager,
                                    syncManager: syncManager
                                )
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
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
