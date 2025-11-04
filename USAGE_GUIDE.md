# Voice Recorder - Quick Usage Guide

## 🎙️ Recording States

The app has **3 distinct states** with different UI:

### 1️⃣ Idle State (Ready to Record)
```
┌─────────────────┐
│ Ready to Record │
│                 │
│       ⭕️        │  ← Large red circle button
│                 │
└─────────────────┘
```
**Action:** Tap the red circle to start recording

---

### 2️⃣ Recording State (Active)
```
┌─────────────────┐
│   Recording     │ ← Red text
│    00:15.3      │ ← Live timer
│   ▂▄▆▄▂        │ ← Animated waveform
│                 │
│  [⏸ Pause]     │ ← Orange button
│  [✓ Finish]    │ ← Red button
└─────────────────┘
```
**Actions:**
- **Pause** → Pauses recording and timer
- **Finish** → Saves recording and returns to idle

---

### 3️⃣ Paused State
```
┌─────────────────┐
│     Paused      │ ← Orange text
│    00:15.3      │ ← Timer frozen
│      ║ ║       │ ← Static pause bars (orange)
│                 │
│  [▶ Resume]    │ ← Green button
│  [✓ Finish]    │ ← Red button
└─────────────────┘
```
**Actions:**
- **Resume** → Continues recording in same file
- **Finish** → Saves recording with current duration

---

## 📋 Complete Recording Workflow

### Simple Recording (No Pause)
1. Tap **red circle** → Start
2. Tap **Finish** → Save
3. Done! ✅

### Recording with Pause/Resume
1. Tap **red circle** → Start recording
2. Tap **Pause** → Recording pauses, timer stops
3. Tap **Resume** → Recording continues (same file!)
4. *(Repeat steps 2-3 as needed)*
5. Tap **Finish** → Save recording
6. Done! ✅

### Example Scenario
```
Action          Time    State
─────────────────────────────────
Start           0:00    Recording
(record...)     0:10    Recording
Pause           0:10    Paused
(waiting...)    0:10    Paused (timer frozen)
Resume          0:10    Recording
(record...)     0:25    Recording
Pause           0:25    Paused
Resume          0:25    Recording
(record...)     0:40    Recording
Finish          0:40    Saved!
```

**Final file:** Single 40-second audio file (paused time NOT included)

---

## 🎯 Key Features

✅ **Continuous Recording**: Pause/resume creates ONE file, not multiple
✅ **Timer Accuracy**: Timer pauses and resumes correctly
✅ **Visual Feedback**:
  - Recording = Red + animated waveform
  - Paused = Orange + static bars
  - Ready = White circle

✅ **No Data Loss**: Pausing doesn't stop the recording session
✅ **Flexible Control**: Pause/resume as many times as needed

---

## 📱 Viewing & Managing Recordings

### Recordings List (Second Tab)
Swipe left or use Digital Crown to access:

```
┌─────────────────────────┐
│     Recordings          │
├─────────────────────────┤
│ ▶ Nov 4, 3:45 PM       │
│   ⏱ 00:42              │
│ ← Swipe left to delete  │
├─────────────────────────┤
│ ▶ Nov 4, 2:30 PM       │
│   ⏱ 01:23              │
└─────────────────────────┘
```

**Actions:**
- **Tap ▶ (play button)** → Play recording
- **Tap again** → Pause playback
- **Swipe left** → Delete recording

---

## 💡 Pro Tips

1. **Long Recordings**: Use pause if you need to organize thoughts or take breaks
2. **No Interruptions**: Pausing keeps the recording session alive - you can pause for minutes
3. **One File**: All pause/resume segments are in the same audio file
4. **Timer Accuracy**: The timer shows exact recording duration (excluding paused time)
5. **Battery Saving**: Pause during long sessions when not actively recording

---

## ⚠️ Important Notes

- **Paused Time ≠ Recorded Time**: Timer only counts active recording
- **Same File**: Resume continues the SAME audio file (not a new one)
- **Finish Anytime**: You can tap Finish while paused - it saves current duration
- **No Auto-Save**: Must tap Finish to save (pausing doesn't save)

---

## 🔧 Troubleshooting

### Timer not updating
→ This is normal when paused! Tap Resume to continue

### Can't find Pause button
→ Pause only appears while actively recording (not in idle state)

### Recording seems short
→ Check if you paused - paused time is not included in final duration

### Want to cancel recording
→ Currently no cancel - tap Finish to save what you have

---

## 🎉 You're Ready!

The pause/resume feature makes it easy to record long-form content with natural breaks. Start recording now!
