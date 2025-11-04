//
//  SyncSetupGuide.swift
//  local-voice-recorder-watch Watch App
//
//  AUTOMATIC SERVER SYNC - SETUP GUIDE
//
//  This file contains setup instructions for the sync functionality.
//  Delete this file after reading or keep for reference.
//

/*

 SYNC SYSTEM OVERVIEW
 ====================

 The app now automatically syncs recordings to a server when connected to WiFi.
 Files are uploaded via REST API and deleted from local storage after successful sync.


 COMPONENTS ADDED
 ================

 1. NetworkMonitor.swift
    - Monitors WiFi/cellular connectivity
    - Uses NWPathMonitor for real-time network status
    - Triggers auto-sync when WiFi becomes available

 2. SyncManager.swift
    - Handles upload logic and retry mechanism
    - Manages sync metadata and status tracking
    - Implements exponential backoff (max 3 retries)
    - Auto-deletes files after successful sync

 3. SyncStatus.swift
    - Defines sync states: notSynced, pending, syncing, synced, failed
    - Provides display text and icons for UI

 4. UI Updates
    - RecordingsListView: Shows WiFi status, sync stats, manual sync button
    - RecordingRowView: Displays sync status icon for each recording


 API CONFIGURATION
 =================

 ✅ CONFIGURED: The app is already configured for local development!

 Current Configuration (SyncManager.swift, lines 31-33):

 ```swift
 private let apiBaseURL = "http://localhost:3000"
 private let apiEndpoint = "/api/recordings"
 private let authToken = ""  // No auth required for local development
 ```

 Timeout & Retry Settings (SyncManager.swift, lines 36-38):

 ```swift
 private let uploadTimeout: TimeInterval = 30.0  // 30 seconds per upload
 private let retryDelays: [TimeInterval] = [5.0, 10.0, 30.0]  // 5s, 10s, 30s backoff
 private let maxRetries = 3  // Maximum 3 upload attempts
 ```


 API ENDPOINT SPECIFICATION
 ==========================

 Expected Server Endpoint:

 POST http://localhost:3000/api/recordings

 Request Format:
 - Content-Type: multipart/form-data
 - Headers: None required (no auth for localhost)
 - Form Fields:
   * audio: <binary audio file data> (filename: recording_TIMESTAMP.m4a)
   * filename: <string> (the file name)
 - Timeout: 30 seconds
 - Retry: 3 attempts with 5s, 10s, 30s delays

 Expected Response:
 - Success: HTTP 200 or 201
 - Failure: Any other status code

 Example Server Implementation (Node.js/Express):

 ```javascript
 const express = require('express');
 const multer = require('multer');
 const app = express();

 const upload = multer({ dest: 'uploads/' });

 app.post('/api/recordings', upload.single('audio'), (req, res) => {
   const filename = req.body.filename;
   const audioFile = req.file;

   console.log('Received recording:', filename);
   console.log('File path:', audioFile.path);
   console.log('File size:', audioFile.size);

   // Save to database/storage
   // ...

   res.status(201).json({
     success: true,
     message: 'Recording uploaded',
     filename: filename
   });
 });

 app.listen(3000, () => {
   console.log('Server running on http://localhost:3000');
 });
 ```


 TESTING THE SYNC
 ================

 QUICK START - Test in 3 Steps:

 1. Start the Server:
    ```bash
    node server.js  # Run the example server above
    ```

 2. Run the Watch App:
    - Build and run on Watch Simulator
    - Simulator is always on WiFi
    - Record a test audio

 3. Check the Logs:
    - Xcode console will show:
      "Uploading recording_XXX.m4a to http://localhost:3000/api/recordings"
      "Upload response status: 201"
      "✓ Successfully uploaded recording_XXX.m4a"
    - Server console will show:
      "Received recording: recording_XXX.m4a"

 2. Real Device Testing:
    - Ensure Apple Watch is connected to WiFi
    - Check WiFi indicator in Recordings tab
    - Tap refresh button to manually trigger sync
    - Monitor sync status icons on each recording

 3. Verify Server Receives Data:
    - Check server logs for POST requests
    - Verify file is saved correctly
    - Confirm response is 200/201


 SYNC STATUS ICONS
 =================

 In the Recordings list, each recording shows:

 - Grey cloud with slash: Not synced yet
 - Orange cloud with arrow: Pending/queued for sync
 - Blue cloud with spinner: Currently uploading
 - Green checkmark cloud: Successfully synced (file deleted locally)
 - Red exclamation cloud: Upload failed


 SYNC BEHAVIOR
 =============

 Automatic Sync:
 - Triggers when new recording is saved
 - Triggers when WiFi connects
 - Only on WiFi (never on cellular)
 - Runs in background

 Manual Sync:
 - Tap refresh button in Recordings tab
 - Requires WiFi connection
 - Syncs all pending recordings

 Retry Logic:
 - Failed uploads retry automatically
 - Maximum 3 attempts per recording
 - After 3 failures, marked as failed
 - Manual sync can retry failed recordings

 File Deletion:
 - Files deleted ONLY after successful upload (200/201 response)
 - Failed uploads keep local copy
 - Prevents data loss


 STORAGE MANAGEMENT
 ==================

 The Recordings tab header shows:
 - WiFi connection status
 - Number of pending recordings
 - Total storage used by recordings
 - Manual sync button


 TROUBLESHOOTING
 ===============

 Problem: Recordings not syncing
 Solution:
 - Check WiFi is connected (indicator in app)
 - Verify API URL is correct in SyncManager.swift
 - Check server is running and accessible
 - Review console logs for error messages

 Problem: All uploads failing
 Solution:
 - Verify server endpoint accepts multipart/form-data
 - Check auth token is correct (if required)
 - Test server endpoint with curl or Postman
 - Ensure server returns 200 or 201 on success

 Problem: Files deleted but not on server
 Solution:
 - This should not happen (deletion only after 200/201)
 - Check sync metadata: sync_metadata.json in Documents
 - Review server logs for received requests


 API TESTING WITH CURL
 =====================

 Test your server endpoint before deploying:

 ```bash
 curl -X POST https://your-api-server.com/api/recordings \
   -H "Authorization: Bearer YOUR_TOKEN" \
   -F "audio=@test_recording.m4a" \
   -F "filename=test_recording.m4a"
 ```

 Expected response: HTTP 200 or 201


 CUSTOMIZATION
 =============

 Change retry count:
 - Edit maxRetries in SyncManager.swift (default: 3)

 Change sync conditions:
 - Edit observeNetworkChanges() in SyncManager.swift
 - Current: Auto-sync on WiFi only
 - Can modify to include cellular (not recommended)

 Add metadata fields:
 - Edit uploadRecording() in SyncManager.swift
 - Add more form fields to multipart body
 - Example: duration, date, device ID

 Custom API response handling:
 - Edit uploadRecording() success/failure logic
 - Currently checks for 200/201 status codes
 - Can add custom error parsing


 SECURITY NOTES
 ==============

 - Use HTTPS for API endpoint (not HTTP)
 - Keep auth token secure (use environment variables in production)
 - Consider implementing refresh tokens for long-lived sessions
 - Validate file types on server side
 - Implement rate limiting on server
 - Add file size limits on server


 PRODUCTION CHECKLIST
 ====================

 Before deploying to production:

 [ ] Configure apiBaseURL with production server
 [ ] Set authToken if API requires authentication
 [ ] Test upload with real recordings
 [ ] Verify server handles multipart/form-data correctly
 [ ] Test WiFi detection on real Apple Watch
 [ ] Verify files are deleted after successful sync
 [ ] Test retry logic with temporary server failures
 [ ] Monitor server logs for upload errors
 [ ] Test with multiple recordings (batch sync)
 [ ] Verify storage calculations are accurate
 [ ] Test manual sync button functionality


 MONITORING & LOGS
 =================

 The sync system logs to console:
 - Upload start/completion
 - Success/failure status
 - Error messages
 - File deletion confirmations

 Use Xcode console to monitor sync activity during development.

 In production, consider adding:
 - Analytics for sync success/failure rates
 - Server-side logging for received uploads
 - Alert for repeated failures

 */

// This file can be deleted after reading.
// All setup is done in SyncManager.swift (lines 24-26)

import Foundation

// No executable code in this file - it's documentation only
