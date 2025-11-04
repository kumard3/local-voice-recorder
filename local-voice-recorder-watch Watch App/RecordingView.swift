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
        VStack(spacing: 0) {
            if audioManager.isRecording || audioManager.isPaused {
                // Timer at top-left (like Apple Music track title)
                HStack {
                    Text(timeString(from: audioManager.currentRecordingTime))
                        .font(.system(size: 20, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.top, 8)
                .padding(.bottom, 20)
                
                Spacer()
                
                // Waveform centered (separated from title)
                VStack {
                    if audioManager.isRecording && !audioManager.isPaused {
                        AudioWaveView(audioLevel: audioManager.audioLevel)
                            .frame(height: 60)
                    } else if audioManager.isPaused {
                        AudioWaveView(audioLevel: 0.0)
                            .frame(height: 60)
                            .opacity(0.5)
                    }
                }
                .padding(.bottom, 30)
                
                // Control buttons centered below waveform
                HStack(spacing: 20) {
                    // Pause/Resume button
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

                    // Finish button
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
                
                Spacer()
            } else {
                // Idle state - centered record button
                Spacer()
                Button(action: {
                    audioManager.startRecording()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 80, height: 80)

                        Circle()
                            .stroke(Color.red.opacity(0.4), lineWidth: 2)
                            .frame(width: 70, height: 70)

                        Circle()
                            .fill(Color.red)
                            .frame(width: 60, height: 60)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!audioManager.hasPermission)
                Spacer()
            }
            
            // Error message
            if let error = audioManager.errorMessage {
                Text(error)
                    .font(.caption2)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
        .padding(.bottom, 4)
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var navigationTitle: String {
        if audioManager.isRecording && !audioManager.isPaused {
            return "● Recording"
        } else if audioManager.isPaused {
            return "● Paused"
        }
        return "Record"
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        let milliseconds = Int((timeInterval.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%01d", minutes, seconds, milliseconds)
    }
}

// MARK: - Audio Wave Visualization (Apple-style)
struct AudioWaveView: View {
    let audioLevel: Float
    private let barCount = 16 // Even number for symmetric waveform
    @State private var barHeights: [CGFloat] = Array(repeating: 0.15, count: 16)

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            // Symmetric waveform - bars on both sides
            ForEach(0..<barCount, id: \.self) { index in
                let height = barHeights[index]
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.white)
                    .frame(width: 2)
                    .frame(height: max(3, height * 60))
                    .animation(.easeOut(duration: 0.08), value: height)
            }
        }
        .onChange(of: audioLevel) { newLevel in
            updateWave(level: newLevel)
        }
    }

    private func updateWave(level: Float) {
        // Apple-style: symmetric waveform that responds to audio
        let normalizedLevel = CGFloat(max(0.15, min(1.0, level)))
        
        // Create symmetric pattern - center bars taller, edges shorter
        for i in 0..<barCount {
            let centerIndex = CGFloat(barCount) / 2.0 - 0.5
            let distanceFromCenter = abs(CGFloat(i) - centerIndex) / centerIndex
            
            // Responsiveness decreases from center to edges
            let responsiveness = 1.0 - distanceFromCenter * 0.5
            let targetHeight = normalizedLevel * responsiveness + 0.15 * (1.0 - responsiveness)
            
            // Smooth transition with slight variation
            let variation = CGFloat.random(in: 0.85...1.15)
            let finalTarget = min(1.0, targetHeight * variation)
            
            // Smooth interpolation
            barHeights[i] = barHeights[i] * 0.75 + finalTarget * 0.25
            barHeights[i] = max(0.15, min(1.0, barHeights[i]))
        }
    }
}

#Preview {
    RecordingView(audioManager: AudioManager())
}
