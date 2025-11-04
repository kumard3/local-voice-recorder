//
//  SyncManager.swift
//  local-voice-recorder-watch Watch App
//
//  Manages syncing recordings to server
//
//  FEATURES:
//  - Auto-sync when WiFi available
//  - Upload via REST API (multipart/form-data)
//  - Retry failed uploads (max 3 attempts with exponential backoff: 5s, 10s, 30s)
//  - 30 second timeout per upload attempt
//  - Delete local files after successful sync
//  - Track sync status per recording
//
//  CONFIGURED FOR: http://localhost:3000 (see lines 31-39)
//  TEST SERVER: Run `npm install && npm start` in project root
//

import Foundation
import Combine

@MainActor
class SyncManager: ObservableObject {
    @Published var syncMetadata: [String: SyncMetadata] = [:]
    @Published var isSyncing = false
    @Published var lastSyncError: String?

    private let networkMonitor: NetworkMonitor
    private var cancellables = Set<AnyCancellable>()

    // API Configuration
    // Local development server configuration
    private let apiBaseURL = "http://localhost:3000"
    private let apiEndpoint = "/api/recordings"
    private let authToken = "" // No auth required for local development

    // Retry and timeout configuration
    private let maxRetries = 3
    private let uploadTimeout: TimeInterval = 30.0 // 30 seconds per upload
    private let retryDelays: [TimeInterval] = [5.0, 10.0, 30.0] // Exponential backoff: 5s, 10s, 30s
    private let metadataFileName = "sync_metadata.json"

    init(networkMonitor: NetworkMonitor) {
        self.networkMonitor = networkMonitor
        loadSyncMetadata()
        observeNetworkChanges()
    }

    // MARK: - Network Observation

    private func observeNetworkChanges() {
        // Auto-sync when WiFi becomes available
        networkMonitor.$isWiFi
            .dropFirst() // Skip initial value
            .sink { [weak self] isWiFi in
                if isWiFi {
                    Task {
                        await self?.syncPendingRecordings()
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Sync Metadata Management

    private func loadSyncMetadata() {
        let metadataURL = FileManager.default.documentsDirectory.appendingPathComponent(metadataFileName)

        guard let data = try? Data(contentsOf: metadataURL),
              let metadata = try? JSONDecoder().decode([String: SyncMetadata].self, from: data) else {
            syncMetadata = [:]
            return
        }

        syncMetadata = metadata
    }

    private func saveSyncMetadata() {
        let metadataURL = FileManager.default.documentsDirectory.appendingPathComponent(metadataFileName)

        do {
            let data = try JSONEncoder().encode(syncMetadata)
            try data.write(to: metadataURL)
        } catch {
            print("Failed to save sync metadata: \(error.localizedDescription)")
        }
    }

    // MARK: - Sync Status

    func getSyncStatus(for fileName: String) -> SyncStatus {
        return syncMetadata[fileName]?.status ?? .notSynced
    }

    func markAsNotSynced(_ fileName: String) {
        print("━━━ SYNC: Marking \(fileName) as not synced")
        syncMetadata[fileName] = SyncMetadata(fileName: fileName)
        saveSyncMetadata()
    }

    func removeMetadata(for fileName: String) {
        print("━━━ SYNC: Removing metadata for \(fileName)")
        syncMetadata.removeValue(forKey: fileName)
        saveSyncMetadata()
    }

    // MARK: - Sync Operations

    func syncPendingRecordings() async {
        print("━━━ SYNC: syncPendingRecordings() called")

        guard !isSyncing else {
            print("━━━ SYNC: Already syncing, skipping")
            return
        }

        guard networkMonitor.isWiFi else {
            print("━━━ SYNC: Not on WiFi (isWiFi=\(networkMonitor.isWiFi)), skipping sync")
            return
        }

        print("━━━ SYNC: Starting sync process...")
        isSyncing = true
        lastSyncError = nil

        // Get all recordings that need syncing
        let pendingFiles = syncMetadata.values.filter {
            $0.status == .notSynced || $0.status == .pending || $0.status == .failed
        }

        print("━━━ SYNC: Found \(pendingFiles.count) pending files to sync")

        for metadata in pendingFiles {
            // Check if we've exceeded max retries
            if metadata.attemptCount >= maxRetries {
                print("Max retries exceeded for \(metadata.fileName)")
                continue
            }

            // Apply exponential backoff delay before retry (if this is a retry)
            if metadata.attemptCount > 0 {
                let delayIndex = min(metadata.attemptCount - 1, retryDelays.count - 1)
                let delay = retryDelays[delayIndex]
                print("Waiting \(delay)s before retry attempt \(metadata.attemptCount + 1) for \(metadata.fileName)")
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }

            await uploadRecording(fileName: metadata.fileName)
        }

        isSyncing = false
    }

    func syncRecording(_ fileName: String) async {
        guard networkMonitor.isWiFi else {
            lastSyncError = "WiFi required for sync"
            return
        }

        await uploadRecording(fileName: fileName)
    }

    // Upload a recording to the server using multipart/form-data
    // Expected API response: 200 or 201 for success
    // On success: Recording is marked as synced and deleted from local storage
    // On failure: Status marked as failed, will retry on next sync attempt (max 3 retries)
    private func uploadRecording(fileName: String) async {
        // Update status to syncing
        var metadata = syncMetadata[fileName] ?? SyncMetadata(fileName: fileName)
        metadata.status = .syncing
        metadata.lastSyncAttempt = Date()
        metadata.attemptCount += 1
        syncMetadata[fileName] = metadata
        saveSyncMetadata()

        // Get file URL
        let fileURL = FileManager.default.documentsDirectory.appendingPathComponent(fileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("File not found: \(fileName)")
            updateSyncStatus(fileName: fileName, status: .failed, error: "File not found")
            return
        }

        do {
            // Read file data
            let audioData = try Data(contentsOf: fileURL)

            // Detect file format from filename
            let format = AudioFormat.from(fileName: fileName)

            // Create multipart form data
            let boundary = UUID().uuidString
            var body = Data()

            // Add audio file with correct MIME type
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(format.mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(audioData)
            body.append("\r\n".data(using: .utf8)!)

            print("Uploading \(format.fileExtension.uppercased()) file: \(fileName)")

            // Add metadata
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"filename\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(fileName)\r\n".data(using: .utf8)!)

            body.append("--\(boundary)--\r\n".data(using: .utf8)!)

            // Create request
            guard let url = URL(string: apiBaseURL + apiEndpoint) else {
                updateSyncStatus(fileName: fileName, status: .failed, error: "Invalid API URL")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

            // Add auth token if available
            if !authToken.isEmpty {
                request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            }

            request.httpBody = body
            request.timeoutInterval = uploadTimeout

            // Upload with timeout
            print("Uploading \(fileName) to \(apiBaseURL + apiEndpoint) (attempt \(metadata.attemptCount + 1)/\(maxRetries))")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                updateSyncStatus(fileName: fileName, status: .failed, error: "Invalid response")
                return
            }

            print("Upload response status: \(httpResponse.statusCode)")

            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                // Success - mark as synced and delete local file
                print("✓ Successfully uploaded \(fileName)")
                updateSyncStatus(fileName: fileName, status: .synced, error: nil)
                deleteLocalFile(fileName: fileName)
            } else {
                let errorMsg = "Server error: \(httpResponse.statusCode)"
                updateSyncStatus(fileName: fileName, status: .failed, error: errorMsg)
                print("✗ Upload failed: \(errorMsg)")

                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response: \(responseString)")
                }
            }

        } catch {
            let errorMsg = "Upload error: \(error.localizedDescription)"
            updateSyncStatus(fileName: fileName, status: .failed, error: errorMsg)
            print(errorMsg)
        }
    }

    private func updateSyncStatus(fileName: String, status: SyncStatus, error: String?) {
        var metadata = syncMetadata[fileName] ?? SyncMetadata(fileName: fileName)
        metadata.status = status
        metadata.errorMessage = error
        syncMetadata[fileName] = metadata
        saveSyncMetadata()

        if let error = error {
            lastSyncError = error
        }
    }

    private func deleteLocalFile(fileName: String) {
        let fileURL = FileManager.default.documentsDirectory.appendingPathComponent(fileName)

        do {
            try FileManager.default.removeItem(at: fileURL)
            print("Deleted local file after sync: \(fileName)")
        } catch {
            print("Failed to delete file: \(error.localizedDescription)")
        }
    }

    // MARK: - Manual Sync

    func manualSync() async {
        print("━━━ SYNC: Manual sync triggered")
        await syncPendingRecordings()
    }

    // MARK: - Stats

    func getPendingSyncCount() -> Int {
        return syncMetadata.values.filter {
            $0.status != .synced
        }.count
    }

    func getTotalStorageUsed() -> Int64 {
        var totalSize: Int64 = 0
        let documentsURL = FileManager.default.documentsDirectory

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: [.fileSizeKey])

            for fileURL in fileURLs where fileURL.pathExtension == "m4a" {
                if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        } catch {
            print("Error calculating storage: \(error.localizedDescription)")
        }

        return totalSize
    }

    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
