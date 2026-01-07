# Native iOS Adhan App - Implementation Plan

## Executive Summary

Converting the web-based prayer clock to a native iOS app will solve the unreliable audio playback issues caused by Safari's audio restrictions. This document outlines a comprehensive plan using **SwiftUI** for the native implementation.

---

## Why Audio Fails in Safari (Root Cause)

Safari on iOS has strict audio policies:
1. **Audio context suspension** - iOS suspends audio when the screen locks or Safari goes to background
2. **Memory pressure** - Long-running web apps may have their audio resources reclaimed
3. **Wake lock limitations** - The Web Wake Lock API doesn't guarantee audio playback
4. **User interaction requirement** - Audio can only play after user gesture, but this "permission" can expire
5. **Timer throttling** - Background tabs/apps have their timers heavily throttled

---

## Recommended Approach: SwiftUI Native App

### Why SwiftUI over React Native?
| Factor | SwiftUI | React Native |
|--------|---------|--------------|
| Audio reliability | Full AVAudioSession control | Still uses bridges, can have issues |
| Background modes | Native support | Requires native modules |
| Local notifications | Native integration | Requires native modules |
| iPad optimization | First-class support | Secondary consideration |
| App size | ~5-10 MB | ~30-50 MB |
| Learning curve | Moderate (if new to Swift) | Lower (if familiar with React) |
| Long-term maintenance | Apple-native, stable | Dependency on RN updates |

**Recommendation: SwiftUI** - For a dedicated prayer app that needs rock-solid audio reliability, native is the right choice.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    SwiftUI Views                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐  │
│  │MainView  │  │PrayerList│  │PrayerApproachingView │  │
│  └──────────┘  └──────────┘  └──────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                    ViewModels                            │
│  ┌──────────────────┐  ┌──────────────────────────┐    │
│  │PrayerTimesManager│  │AdhanAudioManager         │    │
│  │(ObservableObject)│  │(AVAudioSession handling) │    │
│  └──────────────────┘  └──────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                    Services                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐ │
│  │AlAdhanAPI   │  │Location     │  │Notification     │ │
│  │Service      │  │Service      │  │Service          │ │
│  └─────────────┘  └─────────────┘  └─────────────────┘ │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                    Data Layer                            │
│  ┌─────────────────┐  ┌─────────────────────────────┐  │
│  │UserDefaults     │  │Prayer Model                 │  │
│  │(settings)       │  │(Codable structs)            │  │
│  └─────────────────┘  └─────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## Feature Mapping: Web App → Native App

| Web App Feature | Native Implementation |
|-----------------|----------------------|
| Startup overlay for audio | Not needed - native audio works without gesture |
| `adhanAudio.play()` | `AVAudioPlayer` with proper `AVAudioSession` |
| Wake lock API | `UIApplication.shared.isIdleTimerDisabled = true` |
| Geolocation | `CLLocationManager` |
| API fetch | `URLSession` with `async/await` |
| 1-second interval loop | `Timer.publish` or `TimelineView` |
| Local storage | `UserDefaults` or `SwiftData` |
| Background audio | `AVAudioSession.Category.playback` + Background Modes |
| Prayer notifications | `UNUserNotificationCenter` |

---

## Key Implementation Details

### 1. Reliable Audio Playback

```swift
// AdhanAudioManager.swift
import AVFoundation

class AdhanAudioManager: ObservableObject {
    private var audioPlayer: AVAudioPlayer?

    init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // .playback allows audio even when silent switch is on
            // mixWithOthers can be removed if you want to pause other audio
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }

    func playAdhan() {
        guard let url = Bundle.main.url(forResource: "adhan", withExtension: "mp3") else {
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Adhan playback error: \(error)")
        }
    }
}
```

### 2. Background Audio (Screen Locked)

In Xcode, enable **Background Modes** → **Audio, AirPlay, and Picture in Picture**

This allows the adhan to play even when:
- Screen is locked
- App is in background
- Device is in Do Not Disturb (audio still plays)

### 3. Local Notifications as Backup

Even if the app is terminated, local notifications can alert the user:

```swift
// NotificationService.swift
import UserNotifications

class NotificationService {
    func scheduleAdhanNotification(for prayer: Prayer) {
        let content = UNMutableNotificationContent()
        content.title = "Time for \(prayer.name)"
        content.body = "It's time for \(prayer.name) prayer"
        content.sound = UNNotificationSound(named: UNNotificationSoundName("adhan.mp3"))

        let components = Calendar.current.dateComponents(
            [.hour, .minute],
            from: prayer.time
        )
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: prayer.id,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func scheduleAllPrayers(_ prayers: [Prayer]) {
        // Remove old notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        // Schedule new ones
        for prayer in prayers {
            scheduleAdhanNotification(for: prayer)
        }
    }
}
```

**Note:** Custom notification sounds are limited to 30 seconds. For the full adhan:
- Use a 30-second clip for notification
- When user opens app, play full adhan if within time window

### 4. Screen Always-On (Kiosk Mode)

```swift
// In your main view
.onAppear {
    UIApplication.shared.isIdleTimerDisabled = true // Prevents screen dimming
}
.onDisappear {
    UIApplication.shared.isIdleTimerDisabled = false
}
```

Combined with **Guided Access** on iPad, this creates a true kiosk experience.

---

## Project Structure

```
AdhanApp/
├── AdhanApp.swift                 # App entry point
├── ContentView.swift              # Main view
├── Models/
│   ├── Prayer.swift               # Prayer data model
│   ├── PrayerSchedule.swift       # Daily schedule model
│   └── HijriDate.swift            # Islamic date model
├── Views/
│   ├── MainClockView.swift        # Large time display
│   ├── PrayerListView.swift       # Prayer times grid
│   ├── NextPrayerView.swift       # "Next: Dhuhr @ 12:30"
│   ├── DateHeaderView.swift       # Gregorian + Hijri dates
│   └── PrayerIndicatorView.swift  # Approaching/active indicator
├── ViewModels/
│   ├── PrayerTimesManager.swift   # Main business logic
│   └── AdhanAudioManager.swift    # Audio handling
├── Services/
│   ├── AlAdhanAPIService.swift    # API calls
│   ├── LocationService.swift      # CLLocationManager wrapper
│   └── NotificationService.swift  # Local notifications
├── Utilities/
│   ├── TimeFormatter.swift        # 24-hour formatting
│   └── DateHelpers.swift          # Date calculations
├── Resources/
│   ├── adhan.mp3                  # Full adhan audio
│   ├── adhan-short.caf            # 30-sec notification sound
│   └── mosque.jpg                 # Background image
└── Info.plist                     # App configuration
```

---

## Step-by-Step Implementation Plan

### Phase 1: Project Setup
1. Create new Xcode project (SwiftUI, iPad target)
2. Configure deployment target (iOS 16+ recommended for modern SwiftUI)
3. Add Background Modes capability (Audio)
4. Add Location permission descriptions to Info.plist
5. Add Notification permission request
6. Import audio file (adhan.mp3) and background image

### Phase 2: Data Layer
1. Create `Prayer` model (name, time, timestamp)
2. Create `PrayerSchedule` model
3. Implement `AlAdhanAPIService` using URLSession + async/await
4. Add JSON decoding for API response
5. Test API calls in SwiftUI Preview

### Phase 3: Core Logic
1. Implement `PrayerTimesManager` (ObservableObject)
   - Fetch today's prayers
   - Track current/next prayer
   - Handle day rollover
   - Implement timer-based updates
2. Implement `LocationService` with CLLocationManager
3. Implement fallback to Queens, NY coordinates

### Phase 4: Audio System
1. Create `AdhanAudioManager`
2. Configure AVAudioSession for reliable playback
3. Implement play/pause/stop controls
4. Test with screen locked
5. Test with app in background

### Phase 5: UI Implementation
1. Create main layout matching web app design
2. Implement `MainClockView` (large time display)
3. Implement `DateHeaderView` (Bismillah + dates)
4. Implement `PrayerListView` (5 prayer cards)
5. Implement `NextPrayerView` with animation
6. Implement `PrayerIndicatorView` (corner indicator)
7. Add night mode dimming overlay
8. Style with Islamic aesthetic (gold accents, serif fonts)

### Phase 6: Notifications
1. Request notification permission on first launch
2. Schedule notifications for each prayer
3. Create short adhan clip for notification sound
4. Re-schedule notifications daily at midnight

### Phase 7: Polish & Testing
1. Test on physical iPad (simulator audio is unreliable)
2. Test screen-off audio playback
3. Test day rollover at midnight
4. Test timezone changes
5. Test after device restart
6. Add error handling and offline support
7. Cache last-known prayer times in UserDefaults

### Phase 8: Deployment
1. Configure App Store Connect
2. Create app icons and screenshots
3. Write App Store description
4. Submit for TestFlight testing
5. Submit for App Store review

---

## Timeline Considerations

This plan focuses on what needs to be done, not when. The phases are ordered by dependency:
- Phase 1-2 can be done together
- Phase 3-4 depend on Phase 2
- Phase 5 can start in parallel with Phase 3-4
- Phase 6-8 require earlier phases to be complete

---

## Alternative: Hybrid Approach

If you want to minimize development effort while still getting reliable audio:

### Option A: WKWebView + Native Audio Bridge
- Wrap existing web app in a WKWebView
- Use native Swift code only for audio playback
- JavaScript bridge calls native audio methods
- Pros: Reuse existing UI code
- Cons: Still some web limitations, two codebases to maintain

### Option B: iOS Shortcuts + Existing Web App
- Keep web app for display
- Use iOS Shortcuts app to schedule alarms at prayer times
- Shortcuts can play sounds reliably
- Pros: No new app development
- Cons: Manual setup, less elegant, requires fetching times externally

---

## Recommended Next Steps

1. **Confirm technology choice**: SwiftUI native (recommended) vs hybrid
2. **Set up development environment**: Xcode 15+, Apple Developer account
3. **Start with Phase 1-2**: Get project scaffolded and API working
4. **Prototype audio early**: Validate that AVAudioSession solves the reliability issue before building full UI

---

## Resources

- [AVAudioSession Best Practices](https://developer.apple.com/documentation/avfaudio/avaudiosession)
- [Background Execution Guide](https://developer.apple.com/documentation/uikit/app_and_environment/scenes/preparing_your_ui_to_run_in_the_background)
- [Local Notifications](https://developer.apple.com/documentation/usernotifications)
- [AlAdhan API Documentation](https://aladhan.com/prayer-times-api)
- [SwiftUI for iPad](https://developer.apple.com/documentation/swiftui/building-layouts-with-stack-views)

---

## Questions to Consider

1. **Apple Developer Account**: Do you have one? ($99/year required for App Store)
2. **TestFlight**: Would you want to distribute via TestFlight first for testing?
3. **Features to add**: Should we add any features not in the web app?
   - Multiple adhan audio options?
   - Prayer time adjustment settings?
   - Qibla direction compass?
   - Widget for home screen?
4. **iPad-only or iPhone too?**: The current design is iPad-optimized; should we support iPhone?
