//
//  RecordingView.swift
//  local-voice-recorder-watch Watch App
//
//  Created by Kumar Deepanshu on 11/4/25.
//

import SwiftUI

struct RecordingView: View {
    @ObservedObject var audioManager: AudioManager
    @State private var pulseAnimation = false

    var body: some View {
        VStack(spacing: 12) {
            // Recording status and timer
            VStack(spacing: 6) {
                if audioManager.isRecording && !audioManager.isPaused {
                    Text("Recording")
                        .font(.headline)
                        .foregroundColor(.red)
                } else if audioManager.isPaused {
                    Text("Paused")
                        .font(.headline)
                        .foregroundColor(.orange)
                } else {
                    Text("Ready to Record")
                        .font(.headline)
                        .foregroundColor(.gray)
                }

                // Timer display
                if audioManager.isRecording || audioManager.isPaused {
                    Text(timeString(from: audioManager.currentRecordingTime))
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)

                    // Animated waveform indicator (only when actively recording)
                    if audioManager.isRecording && !audioManager.isPaused {
                        HStack(spacing: 3) {
                            ForEach(0..<5) { index in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.red)
                                    .frame(width: 3, height: CGFloat.random(in: 8...20))
                                    .animation(
                                        Animation.easeInOut(duration: 0.5)
                                            .repeatForever()
                                            .delay(Double(index) * 0.1),
                                        value: pulseAnimation
                                    )
                            }
                        }
                        .frame(height: 24)
                        .onAppear {
                            pulseAnimation.toggle()
                        }
                    } else if audioManager.isPaused {
                        // Paused indicator - static bars
                        HStack(spacing: 3) {
                            ForEach(0..<2) { _ in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.orange)
                                    .frame(width: 5, height: 16)
                            }
                        }
                        .frame(height: 24)
                    }
                }
            }

            Spacer()

            // Control buttons based on state
            if audioManager.isRecording || audioManager.isPaused {
                // Recording or Paused state - show Pause/Resume and Finish buttons in HStack
                HStack(spacing: 8) {
                    // Pause/Resume button
                    Button(action: {
                        if audioManager.isPaused {
                            audioManager.resumeRecording()
                        } else {
                            audioManager.pauseRecording()
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: audioManager.isPaused ? "play.circle.fill" : "pause.circle.fill")
                                .font(.title2)
                            Text(audioManager.isPaused ? "Resume" : "Pause")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 8)
                        .background(audioManager.isPaused ? Color.green : Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Finish button
                    Button(action: {
                        audioManager.finishRecording()
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                            Text("Finish")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 8)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 4)
            } else {
                // Idle state - show Record button
                Button(action: {
                    audioManager.startRecording()
                }) {
                    ZStack {
                        // Outer circle
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 70, height: 70)

                        // Inner circle
                        Circle()
                            .fill(Color.red)
                            .frame(width: 60, height: 60)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!audioManager.hasPermission)
            }

            Spacer()

            // Error message
            if let error = audioManager.errorMessage {
                Text(error)
                    .font(.caption2)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .navigationTitle("Record")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        let milliseconds = Int((timeInterval.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%01d", minutes, seconds, milliseconds)
    }
}

#Preview {
    RecordingView(audioManager: AudioManager())
}
