# Native iOS Adhan App - Implementation Roadmap

## Key Decisions

### Apple Developer Account
**You do NOT need a paid developer account for personal testing.**

- **Free Apple ID**: Build and run on your own iPad using just Xcode and your Apple ID
- **Limitation**: Apps expire after 7 days and need to be reinstalled
- **Workaround**: Simply rebuild from Xcode when it expires (connect iPad, click Run)
- **When you need $99/year account**: Only for TestFlight or App Store distribution

### iOS Version Target
**Target: iOS 15.0**

iOS 15 supports iPads from 2014 onwards (iPad Air 2) while providing solid SwiftUI APIs. This is the right balance between device compatibility and API availability.

### Scope: Kiosk Mode Only (v1)

**IN SCOPE:**
- SwiftUI iPad app, iOS 15.0+, landscape only
- Screen always-on for reliable timer operation
- AlAdhan API integration with Queens, NY fallback
- Reliable audio playback with screen locked
- Location services for automatic prayer times
- Day rollover and midnight refresh
- First-run Guided Access instructions
- Offline caching of last successful prayer times

**OUT OF SCOPE (v1):**
- Local notifications (not needed for always-on kiosk)
- iPhone support
- Settings screens
- Multiple adhan options
- App Store distribution

---

## Critical Success Factor

**The entire reason for going native is reliable audio with screen locked.**

Phase 2 (Audio System) must be validated on a physical iPad BEFORE proceeding with other phases. If audio doesn't play reliably with the screen locked, we need to debug that first.

---

## Implementation Phases

### Phase 0: Project Foundation
**Goal**: Empty app builds and runs on iPad Simulator

| Task | Description | Validation |
|------|-------------|------------|
| 0.1 | Create Xcode project (SwiftUI, iOS 15, iPad) | Project opens in Xcode |
| 0.2 | Configure folder structure | Files organized per architecture |
| 0.3 | Add background audio capability | Info.plist has UIBackgroundModes with "audio" |
| 0.4 | Add location permission strings | Info.plist has NSLocationWhenInUseUsageDescription |
| 0.5 | Verify adhan.mp3 format | Plays in QuickTime/Preview |
| 0.6 | Resize mosque.jpg to 2732x2048 | Single high-res image for all iPads |
| 0.7 | Import assets to project | Resources appear in Xcode |
| 0.8 | Create placeholder ContentView | App shows "Adhan App" on simulator |

**Exit Criteria**: `⌘R` builds and runs on iOS Simulator showing placeholder UI.

---

### Phase 1: Data Layer
**Goal**: Can fetch and parse prayer times from AlAdhan API
**Parallel**: Can run with Phase 2

| Task | Description | Validation |
|------|-------------|------------|
| 1.1 | Create `Prayer` model (Codable) | Struct compiles |
| 1.2 | Create `AlAdhanResponse` models | Matches API JSON structure |
| 1.3 | Implement `AlAdhanService` with async/await | Console prints prayer times |
| 1.4 | Add error handling (network failures, bad data) | Errors are caught and logged |
| 1.5 | Add fallback coordinates (Queens, NY: 40.7282, -73.7949) | Falls back when location unavailable |
| 1.6 | Add timezone handling | Passes device timezone to API |
| 1.7 | Cache last successful prayer times in UserDefaults | Can display times when offline |
| 1.8 | Implement retry logic (3 attempts, exponential backoff) | Handles transient failures |

**Exit Criteria**: Can call `AlAdhanService.shared.fetchPrayerTimes()` and get back 5 `Prayer` objects.

---

### Phase 2: Audio System (CRITICAL)
**Goal**: Adhan plays reliably with screen locked
**Parallel**: Can run with Phase 1

| Task | Description | Validation |
|------|-------------|------------|
| 2.1 | Create `AdhanAudioManager` class | Class compiles |
| 2.2 | Configure AVAudioSession for .playback category | No errors on session setup |
| 2.3 | Implement `playAdhan()` method | Audio plays when called |
| 2.4 | Implement `stopAdhan()` method | Audio stops when called |
| 2.5 | Add audio interruption handling | Resumes after phone call |
| 2.6 | **TEST: Screen locked playback** | Audio continues with screen off |
| 2.7 | **TEST: App backgrounded playback** | Audio continues in background |
| 2.8 | **TEST: After other app audio** | Adhan plays after using another audio app |

**Exit Criteria**: Adhan plays reliably with screen locked and app backgrounded.

**STOP POINT**: If 2.6-2.8 fail, debug before proceeding. This is the core problem we're solving.

---

### Phase 3: Core Logic
**Goal**: App automatically plays adhan at prayer time
**Requires**: Phase 1 and Phase 2 complete

| Task | Description | Validation |
|------|-------------|------------|
| 3.1 | Create `PrayerTimesManager` (ObservableObject) | Class compiles with @Published vars |
| 3.2 | Implement prayer fetching on init | Prayers load when manager created |
| 3.3 | Implement `nextPrayer` computed property | Returns correct upcoming prayer |
| 3.4 | Implement 1-second timer for current time | Time updates every second |
| 3.5 | Implement prayer time detection | Detects when current time >= prayer time |
| 3.6 | Trigger adhan playback at prayer time | Adhan plays automatically |
| 3.7 | Track played prayers (Set<String>) | Same prayer doesn't trigger twice |
| 3.8 | Implement day rollover (1 hour after Isha) | Fetches next day's prayers |
| 3.9 | Implement midnight refresh | Refreshes data at 00:01 |
| 3.10 | Handle timezone changes | Refetches if timezone changes |

**Exit Criteria**: Set device time to 2 minutes before a prayer, wait, adhan plays automatically.

**Note**: Timer reliability depends on `UIApplication.shared.isIdleTimerDisabled = true` (screen always on). This is set in Phase 5 but is critical for Phase 3 to work long-term.

---

### Phase 4: Location Service
**Goal**: App uses device location for prayer times
**Parallel**: Can run with Phase 3

| Task | Description | Validation |
|------|-------------|------------|
| 4.1 | Create `LocationService` class | Class compiles |
| 4.2 | Request location permission | Permission dialog appears |
| 4.3 | Get current coordinates | Lat/lon returned |
| 4.4 | Implement fallback to Queens, NY | Works when permission denied |
| 4.5 | Reverse geocode for city name | City name displayed |
| 4.6 | Cache last known location | Works after permission revoked |
| 4.7 | Connect to PrayerTimesManager | Uses real location for API |

**Exit Criteria**: App shows correct prayer times for current location, falls back gracefully.

---

### Phase 5: User Interface
**Goal**: UI matches web app appearance
**Requires**: Phase 3 (needs data to display)

| Task | Description | Validation |
|------|-------------|------------|
| 5.1 | Set `isIdleTimerDisabled = true` | Screen stays on |
| 5.2 | Set `UIRequiresFullScreen = YES` | Disables Split View |
| 5.3 | Create `MainClockView` (large time) | Shows current time, updates |
| 5.4 | Create `DateHeaderView` (Bismillah + dates) | Shows Gregorian and Hijri |
| 5.5 | Create `PrayerListView` (5 prayer cards) | Shows all prayers with times |
| 5.6 | Create `NextPrayerView` | Shows "Next: X in Y" |
| 5.7 | Add background image | Mosque image displays |
| 5.8 | Add night mode dimming | Dims after Isha, brightens after Fajr |
| 5.9 | Add location indicator | Shows city name bottom-right |
| 5.10 | Style with gold accents, serif fonts | Matches web app aesthetic |
| 5.11 | iPad landscape optimization | Looks good on all iPad sizes |

**Exit Criteria**: Side-by-side comparison with web app looks equivalent.

---

### Phase 6: First-Run Instructions
**Goal**: User knows how to set up Guided Access

| Task | Description | Validation |
|------|-------------|------------|
| 6.1 | Create `KioskInstructionsView` | View displays |
| 6.2 | Write Guided Access setup steps | Clear instructions |
| 6.3 | Add "Got it" button with UserDefaults | Only shows once |

**Exit Criteria**: First launch shows instructions, subsequent launches go to clock.

---

### Phase 7: Integration & Polish
**Goal**: Production-ready for daily use

| Task | Description | Validation |
|------|-------------|------------|
| 7.1 | Full integration test on iPad | All features work |
| 7.2 | Test 8+ hour operation | All 5 prayers trigger |
| 7.3 | Test after device restart | App works after reboot |
| 7.4 | Test network failure | Shows cached times |
| 7.5 | Test day rollover | Next day's times load |
| 7.6 | Fix discovered issues | All bugs resolved |

**Exit Criteria**: App is stable for daily use.

---

## File Structure

```
AdhanApp/
├── AdhanApp.swift                    # @main entry point
├── ContentView.swift                 # Root view
│
├── Models/
│   ├── Prayer.swift                  # Prayer struct
│   └── AlAdhanResponse.swift         # API response models
│
├── Services/
│   ├── AlAdhanService.swift          # API networking
│   ├── LocationService.swift         # CoreLocation wrapper
│   └── AdhanAudioManager.swift       # AVFoundation audio
│
├── ViewModels/
│   └── PrayerTimesManager.swift      # Main state management
│
├── Views/
│   ├── MainClockView.swift           # Large time display
│   ├── DateHeaderView.swift          # Bismillah + dates
│   ├── PrayerListView.swift          # 5 prayer cards
│   ├── NextPrayerView.swift          # "Next: X in Y"
│   ├── NightOverlayView.swift        # Dimming overlay
│   └── KioskInstructionsView.swift   # First-run guide
│
├── Resources/
│   ├── Assets.xcassets/
│   │   ├── mosque.imageset/          # Background image
│   │   └── AppIcon.appiconset/       # App icons
│   └── adhan.mp3                     # Adhan audio
│
└── Info.plist                        # Permissions & capabilities
```

---

## Validation Checkpoints

| Checkpoint | After Phase | Critical Question |
|------------|-------------|-------------------|
| A | 0 | Can I build and run on Simulator? |
| B | 2 | **Does audio play with screen LOCKED?** |
| C | 1 | Does API return correct prayer times? |
| D | 3 | Does adhan auto-play at prayer time? |
| E | 5 | Does UI match web app? |
| F | 7 | Is it stable for 24-hour use? |

**Checkpoint B is the critical gate.** Do not proceed past Phase 2 until audio works reliably with the screen locked.

---

## Weekly Re-Deployment (Free Apple ID)

Apps signed with free Apple ID expire after 7 days. To refresh:

1. Connect iPad to Mac via USB
2. Open AdhanApp.xcodeproj in Xcode
3. Select your iPad as the target device
4. Click Run (▶️)
5. App is refreshed for another 7 days

**Tip**: Set a recurring calendar reminder for every 6 days.
