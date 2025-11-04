//
//  SyncStatus.swift
//  local-voice-recorder-watch Watch App
//
//  Track sync status for recordings
//

import Foundation

/// Represents the sync state of a recording
enum SyncStatus: String, Codable {
    case notSynced = "not_synced"      // Never uploaded
    case pending = "pending"            // Queued for upload
    case syncing = "syncing"            // Currently uploading
    case synced = "synced"              // Successfully uploaded
    case failed = "failed"              // Upload failed

    var displayText: String {
        switch self {
        case .notSynced: return "Not synced"
        case .pending: return "Pending"
        case .syncing: return "Syncing..."
        case .synced: return "Synced"
        case .failed: return "Failed"
        }
    }

    var iconName: String {
        switch self {
        case .notSynced: return "icloud.slash"
        case .pending: return "icloud.and.arrow.up"
        case .syncing: return "icloud.and.arrow.up"
        case .synced: return "checkmark.icloud.fill"
        case .failed: return "exclamationmark.icloud"
        }
    }
}

/// Tracks sync metadata for a recording
struct SyncMetadata: Codable {
    let fileName: String
    var status: SyncStatus
    var lastSyncAttempt: Date?
    var attemptCount: Int
    var errorMessage: String?

    init(fileName: String) {
        self.fileName = fileName
        self.status = .notSynced
        self.lastSyncAttempt = nil
        self.attemptCount = 0
        self.errorMessage = nil
    }
}
