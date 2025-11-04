//
//  RecordingDetailView.swift
//  local-voice-recorder-watch Watch App
//
//  Created by Kumar Deepanshu on 11/4/25.
//

import SwiftUI
import AVFAudio

struct RecordingDetailView: View {
    let recording: Recording
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var syncManager: SyncManager
    @State private var playbackProgress: TimeInterval = 0
    @State private var playbackTimer: Timer?
    
    private var isCurrentlyPlaying: Bool {
        audioManager.isPlaying && audioManager.currentlyPlayingURL == recording.fileURL
    }
    
    private var syncStatus: SyncStatus {
        syncManager.getSyncStatus(for: recording.fileName)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Play/Pause Button (Large)
                Button(action: {
                    if isCurrentlyPlaying {
                        audioManager.stopPlayback()
                    } else {
                        audioManager.playRecording(recording)
                        startPlaybackTimer()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(isCurrentlyPlaying ? Color.orange.opacity(0.2) : Color.green.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .stroke(isCurrentlyPlaying ? Color.orange : Color.green, lineWidth: 3)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: isCurrentlyPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(isCurrentlyPlaying ? .orange : .green)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 20)
                
                // Recording Info
                VStack(spacing: 8) {
                    Text(recording.displayName)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 12) {
                        Label(recording.durationString, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("•")
                            .foregroundColor(.gray)
                        
                        Text(recording.fileFormat)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                // Playback Progress
                if isCurrentlyPlaying {
                    VStack(spacing: 4) {
                        ProgressView(value: playbackProgress, total: recording.duration)
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                        
                        HStack {
                            Text(timeString(from: playbackProgress))
                                .font(.caption2)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text(timeString(from: recording.duration))
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Sync Status
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: syncStatus.iconName)
                            .foregroundColor(syncStatusColor)
                        
                        Text(syncStatus.displayText)
                            .foregroundColor(.white)
                    }
                    .font(.caption)
                    
                    if syncStatus == .synced {
                        Text("File uploaded successfully")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    } else if syncStatus == .failed {
                        Text("Upload failed. Tap sync to retry.")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.2))
                .cornerRadius(8)
                
                // Delete Button
                Button(role: .destructive) {
                    audioManager.stopPlayback()
                    audioManager.deleteRecording(recording)
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Recording")
                    }
                    .font(.caption)
                }
                .buttonStyle(.bordered)
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle("Recording")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            stopPlaybackTimer()
        }
        .onChange(of: isCurrentlyPlaying) { playing in
            if !playing {
                stopPlaybackTimer()
                playbackProgress = 0
            }
        }
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
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func startPlaybackTimer() {
        stopPlaybackTimer()
        playbackProgress = 0
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                guard let player = audioManager.audioPlayer else {
                    stopPlaybackTimer()
                    return
                }
                if player.isPlaying {
                    playbackProgress = player.currentTime
                } else {
                    stopPlaybackTimer()
                }
            }
        }
    }
    
    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
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
    
    NavigationView {
        RecordingDetailView(
            recording: sampleRecording,
            audioManager: audioManager,
            syncManager: syncManager
        )
    }
}

