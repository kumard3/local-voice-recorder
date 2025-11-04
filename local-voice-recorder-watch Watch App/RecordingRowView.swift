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
        HStack(spacing: 12) {
            // Play button
            Button(action: {
                audioManager.playRecording(recording)
            }) {
                Image(systemName: isCurrentlyPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title3)
                    .foregroundColor(isCurrentlyPlaying ? .orange : .green)
            }
            .buttonStyle(PlainButtonStyle())

            // Date and time
            VStack(alignment: .leading, spacing: 2) {
                Text(dateString)
                    .font(.caption)
                    .foregroundColor(.white)
                
                Text(timeString)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }

            Spacer()

            // Simple sync status
            if syncStatus == .synced {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Image(systemName: "circle")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: recording.date)
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: recording.date)
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
