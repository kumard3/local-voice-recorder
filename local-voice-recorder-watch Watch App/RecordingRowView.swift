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

    private var isCurrentlyPlaying: Bool {
        audioManager.isPlaying && audioManager.currentlyPlayingURL == recording.fileURL
    }

    var body: some View {
        HStack(spacing: 12) {
            // Play/Pause button
            Button(action: {
                audioManager.playRecording(recording)
            }) {
                Image(systemName: isCurrentlyPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(isCurrentlyPlaying ? .orange : .green)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: 30, height: 30)

            // Recording info
            VStack(alignment: .leading, spacing: 4) {
                Text(recording.displayName)
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(.gray)

                    Text(recording.durationString)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color.black.opacity(0.2))
        .cornerRadius(8)
    }
}

#Preview {
    let audioManager = AudioManager()
    let sampleRecording = Recording(
        fileName: "recording_1234567890.m4a",
        date: Date(),
        duration: 125.5
    )

    return RecordingRowView(recording: sampleRecording, audioManager: audioManager)
        .padding()
}
