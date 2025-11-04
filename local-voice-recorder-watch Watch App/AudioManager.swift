//
//  AudioManager.swift
//  local-voice-recorder-watch Watch App
//
//  Created by Kumar Deepanshu on 11/4/25.
//

import Foundation
import AVFoundation
import Combine

@MainActor
class AudioManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var isPlaying = false
    @Published var recordings: [Recording] = []
    @Published var currentRecordingTime: TimeInterval = 0
    @Published var hasPermission = false
    @Published var errorMessage: String?
    @Published var currentlyPlayingURL: URL?

    private var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    private var recordingTimer: Timer?
    private let audioSession = AVAudioSession.sharedInstance()

    // Sync manager integration
    var syncManager: SyncManager?

    override init() {
        super.init()
        setupAudioSession()
        loadRecordings()
    }

    func setSyncManager(_ manager: SyncManager) {
        self.syncManager = manager

        // Now that sync manager is set, mark existing recordings as unsynced
        print("━━━ AUDIO: SyncManager connected, checking existing recordings")
        for recording in recordings {
            if syncManager?.syncMetadata[recording.fileName] == nil {
                print("━━━ AUDIO: Marking existing recording as unsynced: \(recording.fileName)")
                syncManager?.markAsNotSynced(recording.fileName)
            }
        }

        // Trigger sync for any unsynced recordings
        Task {
            await syncManager?.syncPendingRecordings()
        }
    }
    
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            requestMicrophonePermission()
        } catch {
            errorMessage = "Failed to setup audio session: \(error.localizedDescription)"
        }
    }
    
    private func requestMicrophonePermission() {
        audioSession.requestRecordPermission { [weak self] allowed in
            DispatchQueue.main.async {
                self?.hasPermission = allowed
                if !allowed {
                    self?.errorMessage = "Microphone permission required"
                }
            }
        }
    }
    
    func startRecording() {
        guard hasPermission else {
            errorMessage = "Microphone permission required"
            return
        }

        guard !isRecording else { return }

        // Use appropriate format based on watchOS version
        let format = AudioFormat.current
        let fileName = "recording_\(Date().timeIntervalSince1970).\(format.fileExtension)"
        let url = FileManager.default.documentsDirectory.appendingPathComponent(fileName)

        let settings = format.settings

        print("Recording with format: \(format.fileExtension.uppercased())")
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            isRecording = true
            currentRecordingTime = 0
            errorMessage = nil
            
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.updateRecordingTime()
            }
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }
    
    func pauseRecording() {
        guard isRecording && !isPaused else { return }

        audioRecorder?.pause()
        recordingTimer?.invalidate()
        recordingTimer = nil
        isPaused = true
    }

    func resumeRecording() {
        guard isRecording && isPaused else { return }

        audioRecorder?.record()
        isPaused = false

        // Restart the timer
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateRecordingTime()
        }
    }

    func finishRecording() {
        guard isRecording else { return }

        audioRecorder?.stop()
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false
        isPaused = false
    }

    func stopRecording() {
        // Keep this for backwards compatibility - now calls finishRecording
        finishRecording()
    }
    
    private func updateRecordingTime() {
        guard let recorder = audioRecorder else { return }
        currentRecordingTime = recorder.currentTime
    }
    
    func playRecording(_ recording: Recording) {
        if isPlaying && currentlyPlayingURL == recording.fileURL {
            stopPlayback()
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recording.fileURL)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            isPlaying = true
            currentlyPlayingURL = recording.fileURL
            errorMessage = nil
        } catch {
            errorMessage = "Failed to play recording: \(error.localizedDescription)"
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentlyPlayingURL = nil
    }
    
    func deleteRecording(_ recording: Recording) {
        do {
            // Delete the audio file
            try FileManager.default.removeItem(at: recording.fileURL)

            // Remove from recordings list
            recordings.removeAll { $0.id == recording.id }
            saveRecordings()

            // Clean up sync metadata
            syncManager?.removeMetadata(for: recording.fileName)

            print("Deleted recording: \(recording.fileName)")
        } catch {
            errorMessage = "Failed to delete recording: \(error.localizedDescription)"
            print("Delete error: \(error.localizedDescription)")
        }
    }
    
    private func loadRecordings() {
        let documentsPath = FileManager.default.documentsDirectory
        let recordingsURL = documentsPath.appendingPathComponent("recordings.json")

        guard let data = try? Data(contentsOf: recordingsURL),
              let loadedRecordings = try? JSONDecoder().decode([Recording].self, from: data) else {
            recordings = []
            return
        }

        // Filter out recordings where the actual file doesn't exist
        recordings = loadedRecordings.filter { FileManager.default.fileExists(atPath: $0.fileURL.path) }

        print("━━━ AUDIO: Loaded \(recordings.count) recordings from storage")
        // Note: Sync will be triggered when setSyncManager() is called
    }
    
    private func saveRecordings() {
        let documentsPath = FileManager.default.documentsDirectory
        let recordingsURL = documentsPath.appendingPathComponent("recordings.json")
        
        do {
            let data = try JSONEncoder().encode(recordings)
            try data.write(to: recordingsURL)
        } catch {
            errorMessage = "Failed to save recordings list: \(error.localizedDescription)"
        }
    }
    
    private func addRecording(fileName: String, duration: TimeInterval) {
        let recording = Recording(
            fileName: fileName,
            date: Date(),
            duration: duration
        )
        recordings.insert(recording, at: 0) // Most recent first
        saveRecordings()

        // Mark as not synced in sync manager
        syncManager?.markAsNotSynced(fileName)

        // Trigger auto-sync if on WiFi
        Task {
            await syncManager?.syncPendingRecordings()
        }
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            let fileName = recorder.url.lastPathComponent
            let duration = currentRecordingTime
            addRecording(fileName: fileName, duration: duration)
        } else {
            errorMessage = "Recording failed"
        }
        
        isRecording = false
        currentRecordingTime = 0
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        errorMessage = "Recording error: \(error?.localizedDescription ?? "Unknown error")"
        isRecording = false
        currentRecordingTime = 0
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentlyPlayingURL = nil
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        errorMessage = "Playback error: \(error?.localizedDescription ?? "Unknown error")"
        isPlaying = false
        currentlyPlayingURL = nil
    }
}