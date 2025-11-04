//
//  Recording.swift
//  local-voice-recorder-watch Watch App
//
//  Created by Kumar Deepanshu on 11/4/25.
//

import Foundation

struct Recording: Identifiable, Codable {
    let id: UUID
    let fileName: String
    let date: Date
    let duration: TimeInterval

    init(id: UUID = UUID(), fileName: String, date: Date, duration: TimeInterval) {
        self.id = id
        self.fileName = fileName
        self.date = date
        self.duration = duration
    }
    
    var displayName: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var durationString: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var fileURL: URL {
        FileManager.default.documentsDirectory.appendingPathComponent(fileName)
    }
}

extension FileManager {
    var documentsDirectory: URL {
        urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}