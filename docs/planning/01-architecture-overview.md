# Native iOS Adhan App - Architecture Overview

## Why Native iOS?

Safari on iOS has strict audio policies that cause unreliable adhan playback:
1. **Audio context suspension** - iOS suspends audio when screen locks
2. **Memory pressure** - Long-running web apps lose audio resources
3. **Timer throttling** - Background tabs have timers heavily throttled
4. **User interaction requirement** - Audio "permission" can expire

A native iOS app with proper `AVAudioSession` configuration solves all of these.

---

## Technology Choice: SwiftUI

| Factor | SwiftUI | React Native |
|--------|---------|--------------|
| Audio reliability | Full AVAudioSession control | Bridge-based, can have issues |
| Background modes | Native support | Requires native modules |
| iPad optimization | First-class | Secondary |
| App size | ~5-10 MB | ~30-50 MB |
| Maintenance | Apple-native, stable | RN update dependency |

**Decision**: Pure SwiftUI for maximum reliability.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    SwiftUI Views                         │
│  ┌──────────────┐ ┌────────────┐ ┌──────────────────┐  │
│  │MainClockView │ │PrayerList  │ │KioskInstructions │  │
│  │DateHeader    │ │NextPrayer  │ │NightOverlay      │  │
│  └──────────────┘ └────────────┘ └──────────────────┘  │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                    ViewModel                             │
│           ┌──────────────────────────┐                  │
│           │   PrayerTimesManager     │                  │
│           │   (ObservableObject)     │                  │
│           │                          │                  │
│           │ @Published prayers       │                  │
│           │ @Published nextPrayer    │                  │
│           │ @Published currentTime   │                  │
│           │ @Published locationName  │                  │
│           └──────────────────────────┘                  │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                    Services                              │
│  ┌─────────────────┐ ┌─────────────────┐ ┌───────────┐ │
│  │ AlAdhanService  │ │ LocationService │ │AdhanAudio │ │
│  │ (API + Cache)   │ │ (CoreLocation)  │ │ Manager   │ │
│  └─────────────────┘ └─────────────────┘ └───────────┘ │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                    Data Layer                            │
│  ┌─────────────────────┐ ┌────────────────────────────┐│
│  │ UserDefaults        │ │ Prayer Model (Codable)     ││
│  │ - cached prayers    │ │ - name: String             ││
│  │ - cached location   │ │ - time: Date               ││
│  │ - hasSeenInstructions│ │ - arabicName: String      ││
│  └─────────────────────┘ └────────────────────────────┘│
└─────────────────────────────────────────────────────────┘
```

---

## Feature Mapping: Web App → Native

| Web App | Native iOS |
|---------|-----------|
| Startup overlay for audio | Not needed - native audio works |
| `adhanAudio.play()` | `AVAudioPlayer` with `AVAudioSession` |
| Wake Lock API | `isIdleTimerDisabled = true` |
| Geolocation API | `CLLocationManager` |
| `fetch()` | `URLSession` with `async/await` |
| `setInterval(1000)` | `Timer.publish` |
| localStorage | `UserDefaults` |
| Background audio | `AVAudioSession.Category.playback` |

---

## Key Implementation Details

### 1. Reliable Audio Playback

```swift
class AdhanAudioManager: ObservableObject {
    private var audioPlayer: AVAudioPlayer?

    init() {
        configureAudioSession()
        observeInterruptions()
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // .playback allows audio with screen locked and silent switch on
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }

    private func observeInterruptions() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        if type == .ended {
            // Resume playback after interruption (e.g., phone call ended)
            try? AVAudioSession.sharedInstance().setActive(true)
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
            print("Playback error: \(error)")
        }
    }
}
```

### 2. Screen Always-On (Critical for Timer Reliability)

```swift
struct ContentView: View {
    var body: some View {
        MainPrayerView()
            .onAppear {
                // Prevents screen from dimming/locking
                UIApplication.shared.isIdleTimerDisabled = true
            }
    }
}
```

**Why this matters**: The 1-second timer that checks for prayer times will only fire reliably if the app is in the foreground. With `isIdleTimerDisabled = true`, the screen stays on and the timer runs continuously.

### 3. API Service with Caching

```swift
class AlAdhanService {
    static let shared = AlAdhanService()

    private let cacheKey = "cachedPrayerTimes"
    private let cacheDateKey = "cachedPrayerDate"

    func fetchPrayerTimes(latitude: Double, longitude: Double) async throws -> [Prayer] {
        // Try network first
        do {
            let prayers = try await fetchFromAPI(latitude: latitude, longitude: longitude)
            cache(prayers)
            return prayers
        } catch {
            // Fall back to cache if network fails
            if let cached = getCachedPrayers(), isCacheValidForToday() {
                return cached
            }
            throw error
        }
    }

    private func cache(_ prayers: [Prayer]) {
        // Store in UserDefaults for offline access
        if let data = try? JSONEncoder().encode(prayers) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: cacheDateKey)
        }
    }
}
```

### 4. Location Service with Fallback

```swift
class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    // Queens, NY fallback coordinates
    static let fallbackLatitude = 40.7282
    static let fallbackLongitude = -73.7949
    static let fallbackCity = "Queens, NY"

    func requestLocation() async -> (lat: Double, lon: Double, city: String) {
        // Request permission and get location
        // If denied or error, return fallback
        return (Self.fallbackLatitude, Self.fallbackLongitude, Self.fallbackCity)
    }
}
```

---

## Info.plist Requirements

```xml
<!-- Background Audio -->
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>

<!-- Location Permission -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>Your location is used to calculate accurate prayer times for your area.</string>

<!-- Force Full Screen (disable Split View) -->
<key>UIRequiresFullScreen</key>
<true/>

<!-- iPad Landscape Only -->
<key>UISupportedInterfaceOrientations~ipad</key>
<array>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
</array>
```

---

## Prayer Time Logic

### Day Rollover Strategy

```
Timeline:
├── Fajr (e.g., 5:30 AM)
├── Dhuhr (e.g., 12:30 PM)
├── Asr (e.g., 3:45 PM)
├── Maghrib (e.g., 6:15 PM)
├── Isha (e.g., 7:45 PM)
│
├── Isha + 1 hour → Fetch tomorrow's times
│
└── 00:01 AM → Refresh today's data (now "tomorrow" is "today")
```

**Why 1 hour after Isha?**
- Gives buffer for API latency
- Ensures we don't refetch during Isha adhan
- Safe margin before midnight edge cases

### Played Prayer Tracking

```swift
class PrayerTimesManager: ObservableObject {
    private var playedPrayers: Set<String> = []

    private func prayerKey(_ prayer: Prayer) -> String {
        // Unique key per prayer per day
        let dateStr = ISO8601DateFormatter().string(from: prayer.time)
        return "\(prayer.name)-\(dateStr)"
    }

    func checkAndPlayAdhan() {
        guard let next = nextPrayer,
              Date() >= next.time,
              !playedPrayers.contains(prayerKey(next)) else {
            return
        }

        playedPrayers.insert(prayerKey(next))
        audioManager.playAdhan()
        advanceToNextPrayer()
    }
}
```

---

## Error Handling Strategy

| Scenario | Handling |
|----------|----------|
| Network unavailable | Use cached prayer times, show "Offline" indicator |
| API returns error | Retry 3x with backoff, then use cache |
| Location denied | Use Queens, NY fallback |
| Location error | Use last cached location |
| Audio file missing | Log error (should never happen) |
| Audio interrupted | Resume after interruption ends |

---

## Testing Strategy

### Simulator Testing
- UI layout and styling
- API integration
- Date/time logic

### Physical iPad Required
- Audio playback (simulator audio is unreliable)
- Screen lock behavior
- Background audio
- Location services
- Multi-hour operation

### Critical Test Cases
1. Audio plays with screen locked
2. Audio plays after phone call interruption
3. Correct prayer times for current location
4. Day rollover at Isha + 1 hour
5. Midnight refresh
6. Offline mode with cached data
7. 8+ hour continuous operation
