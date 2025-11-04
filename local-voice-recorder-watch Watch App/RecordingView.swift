//
//  RecordingView.swift
//  local-voice-recorder-watch Watch App
//
//  Created by Kumar Deepanshu on 11/4/25.
//

import SwiftUI

struct RecordingView: View {
    @ObservedObject var audioManager: AudioManager

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

                    // Real-time audio level waveform (only when actively recording)
                    if audioManager.isRecording && !audioManager.isPaused {
                        AudioWaveView(audioLevel: audioManager.audioLevel)
                            .frame(height: 40)
                            .padding(.horizontal, 8)
                    } else if audioManager.isPaused {
                        // Paused indicator - static bars
                        HStack(spacing: 3) {
                            ForEach(0..<2) { _ in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.orange)
                                    .frame(width: 5, height: 16)
                            }
                        }
                        .frame(height: 40)
                    }
                }
            }

            Spacer()

            // Control buttons based on state
            if audioManager.isRecording || audioManager.isPaused {
                // Recording or Paused state - show Pause/Resume and Finish buttons
                HStack(spacing: 20) {
                    // Pause/Resume button - circular design
                    Button(action: {
                        if audioManager.isPaused {
                            audioManager.resumeRecording()
                        } else {
                            audioManager.pauseRecording()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(audioManager.isPaused ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                                .frame(width: 50, height: 50)

                            Circle()
                                .stroke(audioManager.isPaused ? Color.green : Color.orange, lineWidth: 2)
                                .frame(width: 50, height: 50)

                            Image(systemName: audioManager.isPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(audioManager.isPaused ? .green : .orange)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Finish button - circular design with stop icon
                    Button(action: {
                        audioManager.finishRecording()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.red.opacity(0.2))
                                .frame(width: 50, height: 50)

                            Circle()
                                .stroke(Color.red, lineWidth: 2)
                                .frame(width: 50, height: 50)

                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.red)
                                .frame(width: 18, height: 18)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            } else {
                // Idle state - show Record button
                Button(action: {
                    audioManager.startRecording()
                }) {
                    ZStack {
                        // Outer glow circle
                        Circle()
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 80, height: 80)

                        // Middle circle
                        Circle()
                            .stroke(Color.red.opacity(0.4), lineWidth: 2)
                            .frame(width: 70, height: 70)

                        // Inner filled circle
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

// MARK: - Audio Wave Visualization
struct AudioWaveView: View {
    let audioLevel: Float
    private let barCount = 12 // Number of bars in the waveform
    @State private var barHeights: [CGFloat] = Array(repeating: 0.1, count: 12)

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.red, .orange]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 3)
                    .frame(height: barHeights[index] * 40) // Max height of 40
                    .animation(.easeInOut(duration: 0.1), value: barHeights[index])
            }
        }
        .onChange(of: audioLevel) { newLevel in
            updateWave(level: newLevel)
        }
    }

    private func updateWave(level: Float) {
        // Shift existing bars to the left (creating scrolling effect)
        barHeights = Array(barHeights.dropFirst()) + [CGFloat(level)]

        // Add some randomness for visual appeal but keep it based on actual level
        // This prevents the wave from looking too uniform
        for i in 0..<barHeights.count {
            let variance = CGFloat.random(in: 0.8...1.2)
            barHeights[i] = max(0.1, min(1.0, barHeights[i] * variance))
        }
    }
}

#Preview {
    RecordingView(audioManager: AudioManager())
}
