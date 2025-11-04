//
//  RecordingRowView.swift
//  local-voice-recorder-watch Watch App
//
//  Created by Kumar Deepanshu on 11/4/25.
//

import SwiftUI

struct RecordingRowView: View {
    let recording: Recording
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var syncManager: SyncManager

    private var isCurrentlyPlaying: Bool {
        audioManager.isPlaying && audioManager.currentlyPlayingURL == recording.fileURL
    }

    private var syncStatus: SyncStatus {
        syncManager.getSyncStatus(for: recording.fileName)
    }

    var body: some View {
        HStack(spacing: 8) {
            // Play/Pause button
            Button(action: {
                audioManager.playRecording(recording)
            }) {
                Image(systemName: isCurrentlyPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(isCurrentlyPlaying ? .orange : .green)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: 28, height: 28)

            // Recording info
            VStack(alignment: .leading, spacing: 3) {
                Text(recording.displayName)
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(.gray)

                    Text(recording.durationString)
                        .font(.caption2)
                        .foregroundColor(.gray)

                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.gray)

                    Text(recording.fileFormat)
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }

            Spacer()

            // Sync status icon
            VStack(spacing: 2) {
                Image(systemName: syncStatus.iconName)
                    .font(.caption)
                    .foregroundColor(syncStatusColor)
                    .opacity(syncStatus == .syncing ? 0.5 : 1.0)

                if syncStatus == .syncing {
                    ProgressView()
                        .scaleEffect(0.5)
                }
            }
            .frame(width: 20)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(Color.black.opacity(0.2))
        .cornerRadius(8)
    }

    private var syncStatusColor: Color {
        switch syncStatus {
        case .notSynced: return .gray
        case .pending: return .orange
        case .syncing: return .blue
        case .synced: return .green
        case .failed: return .red
        }
    }
}

#Preview {
    let audioManager = AudioManager()
    let networkMonitor = NetworkMonitor()
    let syncManager = SyncManager(networkMonitor: networkMonitor)
    let sampleRecording = Recording(
        fileName: "recording_1234567890.m4a",
        date: Date(),
        duration: 125.5
    )

    RecordingRowView(
        recording: sampleRecording,
        audioManager: audioManager,
        syncManager: syncManager
    )
    .padding()
}
