//
//  AudioFormat.swift
//  local-voice-recorder-watch Watch App
//
//  Handle both WAV (watchOS 9) and M4A (watchOS 10+) formats
//
//  WATCHOS VERSION SUPPORT:
//  - watchOS 9.0+: Records in WAV format (uncompressed, larger files)
//  - watchOS 10.0+: Records in M4A format (AAC compressed, smaller files)
//
//  The app automatically detects the watchOS version and uses the appropriate format.
//  Both formats are supported for upload and playback.
//

import Foundation
import AVFoundation

enum AudioFormat {
    case wav
    case m4a

    var fileExtension: String {
        switch self {
        case .wav: return "wav"
        case .m4a: return "m4a"
        }
    }

    var mimeType: String {
        switch self {
        case .wav: return "audio/wav"
        case .m4a: return "audio/m4a"
        }
    }

    var settings: [String: Any] {
        switch self {
        case .wav:
            // WAV format settings for watchOS 9
            return [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsFloatKey: false,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
        case .m4a:
            // M4A/AAC format settings for watchOS 10+
            return [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
        }
    }

    // Determine format based on watchOS version
    static var current: AudioFormat {
        if #available(watchOS 10.0, *) {
            return .m4a
        } else {
            return .wav
        }
    }

    // Detect format from filename
    static func from(fileName: String) -> AudioFormat {
        if fileName.hasSuffix(".wav") {
            return .wav
        } else {
            return .m4a
        }
    }
}
