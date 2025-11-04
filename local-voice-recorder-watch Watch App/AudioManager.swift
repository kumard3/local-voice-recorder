//
//  AudioManager.swift
//  local-voice-recorder-watch Watch App
//
//  Created by Kumar Deepanshu on 11/4/25.
//

import Foundation
import AVFoundation
import Combine
import WatchKit

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
    @Published var audioLevel: Float = 0.0 // Audio level for wave visualization (0.0 to 1.0)

    private var audioRecorder: AVAudioRecorder?
    var audioPlayer: AVAudioPlayer?
    private var recordingTimer: Timer?
    private let audioSession = AVAudioSession.sharedInstance()
    private var isProcessingPauseResume = false

    // Sync manager integration
    var syncManager: SyncManager?

    override init() {
        super.init()
        setupAudioSession()
        loadRecordings()
        
        // Pre-warm timer mechanism to reduce first-time lag
        let _ = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: false) { _ in
            // This helps initialize the timer system
        }
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
            // Configure for background recording support and extended recording
            // Note: allowBluetooth only available on watchOS 11.0+, defaultToSpeaker not available on watchOS
            if #available(watchOS 11.0, *) {
                try audioSession.setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth])
            } else {
                try audioSession.setCategory(.playAndRecord, mode: .default)
            }
            try audioSession.setActive(true)
            requestMicrophonePermission()

            print("━━━ AUDIO: Session configured for extended recording support")
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

        // Check available storage before starting
        if let availableSpace = getAvailableSpace() {
            // Require at least 100 MB free space for safety
            // 1 hour M4A ~15 MB, 1 hour WAV ~300 MB
            let requiredSpace: Int64 = 100 * 1024 * 1024 // 100 MB
            if availableSpace < requiredSpace {
                errorMessage = "Insufficient storage. Please free up space."
                print("━━━ AUDIO: Low storage - Available: \(availableSpace / 1024 / 1024) MB")
                return
            }
        }

        // Use appropriate format based on watchOS version
        let format = AudioFormat.current
        let fileName = "recording_\(Date().timeIntervalSince1970).\(format.fileExtension)"
        let url = FileManager.default.documentsDirectory.appendingPathComponent(fileName)

        let settings = format.settings

        print("━━━ AUDIO: Starting recording with format: \(format.fileExtension.uppercased())")
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true // Enable audio level metering
            audioRecorder?.record()

            isRecording = true
            currentRecordingTime = 0
            errorMessage = nil
            
            // Play start sound
            playStartSound()

            // Timer updates at ~10 FPS for smooth wave animation without excessive CPU usage
            // Reduced from 15 FPS (0.067s) to 10 FPS (0.1s) to prevent audio cycle overload
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.updateRecordingTime()
                self?.updateAudioLevel()
            }
            // Add timer to main run loop to ensure proper execution
            RunLoop.main.add(recordingTimer!, forMode: .common)
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
        }
    }
    
    func pauseRecording() {
        guard isRecording && !isPaused && !isProcessingPauseResume else { return }
        
        isProcessingPauseResume = true
        
        // Stop and clear the timer first to prevent updates
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        // Set paused state for immediate UI update
        isPaused = true
        audioLevel = 0.0 // Reset audio level
        
        // Pause the recorder - use async to avoid blocking
        Task { @MainActor in
            // Small delay to let any pending I/O operations complete
            try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
            
            // Pause the recorder
            audioRecorder?.pause()
            
            isProcessingPauseResume = false
        }
    }

    func resumeRecording() {
        guard isRecording && isPaused && !isProcessingPauseResume else { return }
        
        isProcessingPauseResume = true

        // Update UI state immediately
        isPaused = false

        // Resume recording with proper timing
        Task { @MainActor in
            // Small delay to let audio system prepare
            try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
            
            // Resume recording
            audioRecorder?.record()
            
            // Restart the timer at ~15 FPS for smooth updates
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.067, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.updateRecordingTime()
                    self?.updateAudioLevel()
                }
            }
            
            // Add timer to main run loop
            if let timer = recordingTimer {
                RunLoop.main.add(timer, forMode: .common)
            }
            
            isProcessingPauseResume = false
        }
    }

    func finishRecording() {
        guard isRecording else { return }

        audioRecorder?.stop()
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false
        isPaused = false
        audioLevel = 0.0 // Reset audio level
    }

    func stopRecording() {
        // Keep this for backwards compatibility - now calls finishRecording
        finishRecording()
    }
    
    private func updateRecordingTime() {
        guard let recorder = audioRecorder else { return }
        currentRecordingTime = recorder.currentTime
    }

    private func updateAudioLevel() {
        guard let recorder = audioRecorder, recorder.isRecording else {
            audioLevel = 0.0
            return
        }

        // Update metering data
        recorder.updateMeters()

        // Get average power for channel 0 (mono recording)
        // averagePower returns values from -160 dB (silence) to 0 dB (max)
        let power = recorder.averagePower(forChannel: 0)

        // Normalize to 0.0 - 1.0 range
        // Use -50 dB as minimum (below this is essentially silence)
        // Map -50 to 0 -> 0.0 to 1.0
        let normalizedPower = max(0.0, min(1.0, (power + 50.0) / 50.0))

        // Smooth the transition using exponential moving average
        // This prevents jittery animations
        audioLevel = audioLevel * 0.7 + normalizedPower * 0.3
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

    // Helper function to check available storage space
    func getAvailableSpace() -> Int64? {
        do {
            let systemAttributes = try FileManager.default.attributesOfFileSystem(forPath: FileManager.default.documentsDirectory.path)
            if let freeSpace = systemAttributes[.systemFreeSize] as? Int64 {
                return freeSpace
            }
        } catch {
            print("━━━ AUDIO: Error checking storage: \(error.localizedDescription)")
        }
        return nil
    }
    
    // MARK: - Sound Effects
    
    private func playStartSound() {
        // Play a short beep sound when recording starts
        // Using WatchKit's haptic feedback instead of system sounds for better watchOS experience
        WKInterfaceDevice.current().play(.start)
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