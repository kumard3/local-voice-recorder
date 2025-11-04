# Local Voice Recorder for Apple Watch

A standalone voice recording app for Apple Watch built with SwiftUI and AVFoundation. Record, store, and play back audio directly on your Apple Watch without requiring an iPhone connection.

## Features

- **Standalone Recording**: Record audio directly on Apple Watch without iPhone dependency
- **Local Storage**: All recordings are stored locally on the watch in the app's documents directory
- **Simple UI**: Watch-optimized interface with large tap targets
- **Real-time Monitoring**: Live recording duration display with animated waveform indicator
- **Playback**: Play recordings directly from the watch
- **Manage Recordings**: View all recordings with date, time, and duration; swipe to delete
- **High-Quality Audio**: M4A format with AAC encoding (44.1kHz, mono)

## Architecture

### Core Components

#### 1. **AudioManager.swift**
The central manager handling all audio operations:
- **Recording**: Uses `AVAudioRecorder` with M4A/AAC format
- **Playback**: Uses `AVAudioPlayer` for local playback
- **Permissions**: Requests and manages microphone permissions
- **Storage**: Manages recording metadata and file persistence
- **State Management**: ObservableObject with published properties for SwiftUI

Key Features:
- Real-time recording duration updates (0.1s intervals)
- Automatic metadata tracking (filename, date, duration)
- JSON-based recording list persistence
- Error handling and user feedback
- Audio session management for watch

#### 2. **Recording.swift**
Data model representing a single recording:
- `id`: Unique identifier (UUID)
- `fileName`: M4A file name with timestamp
- `date`: Recording creation date
- `duration`: Recording length in seconds
- Helper properties: `displayName`, `durationString`, `fileURL`
- FileManager extension for documents directory access

#### 3. **ContentView.swift**
Main app container with tab-based navigation:
- TabView with page style for watch-optimized swiping
- Two tabs: Recording and Recordings List
- Shared AudioManager instance across views

#### 4. **RecordingView.swift**
Recording interface:
- Large circular record button (70pt diameter)
- Visual states: Red circle (ready), Red square (recording)
- Real-time timer with millisecond precision
- Animated waveform indicator during recording
- Permission status and error display

#### 5. **RecordingsListView.swift**
List of saved recordings:
- Empty state with helpful message
- ScrollView with LazyVStack for performance
- Swipe-to-delete functionality
- Navigation title and styling

#### 6. **RecordingRowView.swift**
Individual recording row:
- Play/pause button with state indication
- Recording name (formatted date/time)
- Duration display with clock icon
- Visual feedback for currently playing recording

## File Structure

```
local-voice-recorder-watch Watch App/
├── AudioManager.swift           # Core audio recording/playback logic
├── Recording.swift              # Data model and utilities
├── ContentView.swift            # Main app container
├── RecordingView.swift          # Recording interface
├── RecordingsListView.swift    # Recordings list view
├── RecordingRowView.swift       # Individual recording row
├── Info.plist                   # App permissions configuration
└── local_voice_recorder_watchApp.swift  # App entry point
```

## Storage Details

### Location
Recordings are stored in the watch's app-specific documents directory:
```
FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
```

### File Format
- **Audio Files**: `.m4a` extension
- **Naming**: `recording_[timestamp].m4a` (e.g., `recording_1699123456.789.m4a`)
- **Metadata**: `recordings.json` (persisted list of Recording objects)

### Audio Settings
```swift
AVFormatIDKey: kAudioFormatMPEG4AAC  // AAC codec
AVSampleRateKey: 44100.0              // 44.1kHz
AVNumberOfChannelsKey: 1              // Mono
AVEncoderAudioQualityKey: high        // High quality
```

## Permissions

The app requires microphone access. You need to configure this in Xcode:

1. Open `local-voice-recorder-watch.xcodeproj` in Xcode
2. Select the **"local-voice-recorder-watch Watch App"** target
3. Go to the **"Info"** tab
4. Click the **"+"** button to add a new key
5. Select **"Privacy - Microphone Usage Description"** (or type `NSMicrophoneUsageDescription`)
6. Set the value to: `"This app needs access to the microphone to record audio."`

Alternatively, you can add it directly to the target's Info settings:
- Build Settings → Packaging → Info.plist Values
- Add: `NSMicrophoneUsageDescription = This app needs access to the microphone to record audio.`

## Setup Instructions

1. **Open Project**: Open `local-voice-recorder-watch.xcodeproj` in Xcode
2. **Add Microphone Permission**: Follow the steps in the [Permissions](#permissions) section above
3. **Select Target**: Choose your Apple Watch (or Watch Simulator) as the destination
4. **Build and Run**: Click Run or press Cmd+R
5. **Grant Permission**: When prompted, allow microphone access

## Usage

### Recording
1. Launch the app on your Apple Watch
2. You'll start on the "Record" tab
3. Tap the large red circle to start recording
4. The button becomes a red square and shows live duration
5. Tap the square to stop recording
6. Recording is automatically saved

### Viewing Recordings
1. Swipe left or use the Digital Crown to navigate to "Recordings" tab
2. See all your recordings with timestamps and durations
3. Tap the play button to play a recording
4. Tap again to pause
5. Swipe left on a recording row to delete

## Technical Considerations

### Watch-Specific Optimizations
- **Battery**: Recording stops automatically on app backgrounding
- **Storage**: Consider limited watch storage (monitor app size)
- **UI**: Large touch targets (minimum 44pt) for easy interaction
- **Performance**: LazyVStack for efficient list rendering

### Error Handling
The app handles:
- Microphone permission denial
- Recording failures
- Playback errors
- File system errors
- Audio session conflicts

### Limitations
- No cloud sync (local storage only)
- No background recording (stops when app backgrounds)
- Mono audio only (watch has single microphone)
- Limited storage capacity on watch

## Future Enhancements

Potential improvements:
- [ ] Recording quality settings (low/medium/high)
- [ ] Recording name editing
- [ ] Export to iPhone via Watch Connectivity
- [ ] iCloud sync for recordings
- [ ] Complications for quick recording access
- [ ] Recording categories/tags
- [ ] Audio trimming functionality
- [ ] Share recordings via Messages

## Requirements

- watchOS 9.0+
- Xcode 14.0+
- Apple Watch Series 3 or later
- Swift 5.7+

## License

This project is provided as-is for educational purposes.

## Support

For issues or questions, refer to the code comments or Apple's documentation:
- [AVAudioRecorder](https://developer.apple.com/documentation/avfaudio/avaudiorecorder)
- [AVAudioPlayer](https://developer.apple.com/documentation/avfaudio/avaudioplayer)
- [SwiftUI for watchOS](https://developer.apple.com/tutorials/swiftui)
