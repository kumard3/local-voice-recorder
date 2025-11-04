//
//  RecordingsListView.swift
//  local-voice-recorder-watch Watch App
//
//  Created by Kumar Deepanshu on 11/4/25.
//

import SwiftUI

struct RecordingsListView: View {
    @ObservedObject var audioManager: AudioManager

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
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(audioManager.recordings) { recording in
                            RecordingRowView(recording: recording, audioManager: audioManager)
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
        .navigationTitle("Recordings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    let audioManager = AudioManager()
    return NavigationView {
        RecordingsListView(audioManager: audioManager)
    }
}
