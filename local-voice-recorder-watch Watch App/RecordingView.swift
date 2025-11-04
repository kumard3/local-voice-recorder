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
        VStack(spacing: 20) {
            // Recording status and timer
            if audioManager.isRecording {
                VStack(spacing: 8) {
                    Text("Recording")
                        .font(.headline)
                        .foregroundColor(.red)

                    Text(timeString(from: audioManager.currentRecordingTime))
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)

                    // Animated waveform indicator
                    HStack(spacing: 4) {
                        ForEach(0..<5) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.red)
                                .frame(width: 4, height: CGFloat.random(in: 10...30))
                                .animation(
                                    Animation.easeInOut(duration: 0.5)
                                        .repeatForever()
                                        .delay(Double(index) * 0.1),
                                    value: pulseAnimation
                                )
                        }
                    }
                    .frame(height: 30)
                    .onAppear {
                        pulseAnimation.toggle()
                    }
                }
            } else {
                Text("Ready to Record")
                    .font(.headline)
                    .foregroundColor(.gray)
            }

            Spacer()

            // Record/Stop button
            Button(action: {
                if audioManager.isRecording {
                    audioManager.stopRecording()
                } else {
                    audioManager.startRecording()
                }
            }) {
                ZStack {
                    // Outer circle
                    Circle()
                        .stroke(audioManager.isRecording ? Color.red : Color.white, lineWidth: 3)
                        .frame(width: 70, height: 70)

                    // Inner shape (circle for recording, square for stop)
                    if audioManager.isRecording {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.red)
                            .frame(width: 30, height: 30)
                    } else {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 60, height: 60)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!audioManager.hasPermission)

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
        .padding()
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
