# Native iOS Adhan App - Implementation Roadmap

## Key Decisions

### Apple Developer Account
**You do NOT need a paid developer account for personal testing.**

- **Free Apple ID**: You can build and run on your own iPad using just Xcode and your Apple ID
- **Limitation**: Apps expire after 7 days and need to be reinstalled
- **Workaround**: Simply rebuild from Xcode when it expires
- **When you need $99/year account**: Only when you want to distribute via TestFlight or App Store

**For your goal of testing on your own iPad**: Just use your Apple ID in Xcode, no payment required.

### iOS Version Target
**Target: iOS 15.0**

| iOS Version | Oldest Supported iPad | SwiftUI Maturity | Recommendation |
|-------------|----------------------|------------------|----------------|
| iOS 14 | iPad Air 2, iPad mini 4 | Basic | Too many workarounds needed |
| **iOS 15** | **iPad Air 2, iPad mini 4, iPad 5th gen** | **Good** | **Best balance** |
| iOS 16 | iPad Air 3, iPad mini 5, iPad 6th gen | Excellent | Cuts off older devices |

iOS 15 supports iPads from 2014 onwards (iPad Air 2) while giving us solid SwiftUI APIs.

### Scope: Kiosk Mode Only
- No settings screens
- No navigation
- Single-screen app optimized for always-on display
- First-launch instructions for setting up Guided Access

---

## Development Team Structure

Each "team member" is a specialized subagent with focused expertise:

### Team Members

| Role | Responsibility | Key Skills |
|------|---------------|------------|
| **Project Lead** | Xcode setup, project structure, build configuration | Xcode, signing, Info.plist |
| **API Specialist** | AlAdhan API integration, data models, networking | URLSession, Codable, async/await |
| **Audio Engineer** | AVAudioSession, reliable playback, background audio | AVFoundation, audio sessions |
| **UI Developer** | SwiftUI views, layout, animations, styling | SwiftUI, iPad layouts |
| **Core Logic Dev** | Prayer time tracking, timers, day rollover | Combine, Timer, date math |
| **QA Tester** | Validation, testing, edge cases | Testing strategies |

---

## Implementation Phases

### Phase 0: Project Foundation
**Owner**: Project Lead
**Parallel**: No (must complete first)

| Task | Description | Validation |
|------|-------------|------------|
| 0.1 | Create Xcode project (SwiftUI, iOS 15, iPad) | Project opens, builds empty app |
| 0.2 | Configure signing with free Apple ID | Can deploy to simulator |
| 0.3 | Set up folder structure | Files organized per architecture |
| 0.4 | Add background audio capability | Info.plist has UIBackgroundModes |
| 0.5 | Add location permission strings | Info.plist has location descriptions |
| 0.6 | Import assets (adhan.mp3, mosque.jpg) | Resources appear in asset catalog |
| 0.7 | Create placeholder ContentView | App shows "Hello World" on simulator |

**Exit Criteria**: App builds and runs on iOS Simulator showing placeholder UI.

---

### Phase 1: Data Layer
**Owner**: API Specialist
**Parallel**: Can run with Phase 2

| Task | Description | Validation |
|------|-------------|------------|
| 1.1 | Create `Prayer` model (Codable) | Model compiles, can init manually |
| 1.2 | Create `APIResponse` models matching AlAdhan JSON | Can decode sample JSON in test |
| 1.3 | Implement `AlAdhanService` with async/await | Can fetch and print prayer times |
| 1.4 | Add error handling (network failures, bad data) | Errors are caught and logged |
| 1.5 | Add fallback coordinates (Queens, NY) | Falls back when location unavailable |
| 1.6 | Add timezone handling | Passes device timezone to API |

**Exit Criteria**: Can call `AlAdhanService.fetchPrayerTimes()` and get back array of `Prayer` objects.

**Validation Test**:
```swift
// In SwiftUI Preview or test
let prayers = await AlAdhanService.shared.fetchPrayerTimes(
    latitude: 40.7128,
    longitude: -74.0060
)
assert(prayers.count == 5)
print(prayers) // Should show Fajr, Dhuhr, Asr, Maghrib, Isha with times
```

---

### Phase 2: Audio System
**Owner**: Audio Engineer
**Parallel**: Can run with Phase 1

| Task | Description | Validation |
|------|-------------|------------|
| 2.1 | Create `AdhanAudioManager` class | Class compiles |
| 2.2 | Configure AVAudioSession for playback | No errors on session setup |
| 2.3 | Implement `playAdhan()` method | Audio plays when called |
| 2.4 | Test with device screen locked | Audio continues playing |
| 2.5 | Test with app backgrounded | Audio continues playing |
| 2.6 | Implement `stopAdhan()` for manual stop | Audio stops when called |

**Exit Criteria**: Adhan plays reliably with screen locked and app backgrounded.

**Validation Test** (requires physical iPad):
1. Build and run app on iPad
2. Add temporary button that calls `playAdhan()`
3. Tap button, verify audio starts
4. Lock screen while audio is playing
5. Verify audio continues to play
6. If this works, the core problem is solved!

---

### Phase 3: Core Logic
**Owner**: Core Logic Dev
**Parallel**: Requires Phase 1 complete

| Task | Description | Validation |
|------|-------------|------------|
| 3.1 | Create `PrayerTimesManager` (ObservableObject) | Class compiles with @Published vars |
| 3.2 | Implement prayer fetching on init | Prayers load when manager created |
| 3.3 | Implement `nextPrayer` computed property | Returns correct upcoming prayer |
| 3.4 | Implement 1-second timer for current time | Time updates every second |
| 3.5 | Implement prayer time detection | Detects when prayer time is reached |
| 3.6 | Trigger adhan playback at prayer time | Adhan plays automatically |
| 3.7 | Track played prayers (prevent re-trigger) | Same prayer doesn't trigger twice |
| 3.8 | Implement day rollover after Isha | Fetches next day's prayers |
| 3.9 | Implement midnight refresh | Refreshes data at 00:01 |

**Exit Criteria**: App automatically plays adhan when prayer time arrives, advances to next prayer, and handles day rollover.

**Validation Test**:
1. Set device time to 2 minutes before a prayer time
2. Wait and observe
3. At prayer time, adhan should play
4. After 1 minute, next prayer indicator should update
5. Set time to after Isha, verify it fetches next day

---

### Phase 4: Location Service
**Owner**: API Specialist
**Parallel**: Can run with Phase 3

| Task | Description | Validation |
|------|-------------|------------|
| 4.1 | Create `LocationService` class | Class compiles |
| 4.2 | Request location permission | Permission dialog appears |
| 4.3 | Get current coordinates | Lat/lon returned |
| 4.4 | Implement fallback to Queens, NY | Fallback works when denied |
| 4.5 | Reverse geocode for city name display | City name shown correctly |
| 4.6 | Connect to PrayerTimesManager | Uses real location for API call |

**Exit Criteria**: App uses device location for prayer times, falls back gracefully.

---

### Phase 5: User Interface
**Owner**: UI Developer
**Parallel**: Can start with Phase 3, needs Phase 3 complete to finish

| Task | Description | Validation |
|------|-------------|------------|
| 5.1 | Create `MainClockView` (large time display) | Shows current time, updates |
| 5.2 | Create `DateHeaderView` (Bismillah + dates) | Shows Gregorian and Hijri dates |
| 5.3 | Create `PrayerListView` (5 prayer cards) | Shows all 5 prayers with times |
| 5.4 | Create `NextPrayerView` ("Next: X @ time") | Shows next prayer with animation |
| 5.5 | Create `PrayerIndicatorView` (corner) | Shows approaching/active indicator |
| 5.6 | Add background image | Mosque image displays |
| 5.7 | Add night mode dimming overlay | Dims after Isha, brightens after Fajr |
| 5.8 | Add location indicator (bottom right) | Shows city name |
| 5.9 | Style with gold accents, serif fonts | Matches web app aesthetic |
| 5.10 | iPad landscape optimization | Looks good in landscape |

**Exit Criteria**: UI matches web app appearance and updates in real-time.

**Validation**: Side-by-side comparison with web app.

---

### Phase 6: First-Run Kiosk Instructions
**Owner**: UI Developer
**Parallel**: No dependencies

| Task | Description | Validation |
|------|-------------|------------|
| 6.1 | Create `KioskInstructionsView` | View displays instructions |
| 6.2 | Write Guided Access setup instructions | Clear, step-by-step |
| 6.3 | Add "Don't show again" persistence | UserDefaults saves preference |
| 6.4 | Show on first launch only | Only appears once |

**Exit Criteria**: First launch shows helpful instructions, subsequent launches go straight to clock.

**Instructions Content**:
```
Welcome to Adhan Prayer Clock

For the best experience, set up Kiosk Mode:

1. Go to Settings → Accessibility → Guided Access
2. Turn on Guided Access
3. Set a passcode
4. Return to this app
5. Triple-click the side button
6. Tap "Start" in the top right

This keeps the prayer clock always visible and
prevents accidental exits.

[Got it, don't show again]
```

---

### Phase 7: Integration & Polish
**Owner**: QA Tester + All
**Parallel**: No (final phase)

| Task | Description | Validation |
|------|-------------|------------|
| 7.1 | Full integration test on physical iPad | All features work together |
| 7.2 | Test 24-hour continuous operation | No crashes or memory leaks |
| 7.3 | Test after device restart | App works after reboot |
| 7.4 | Test timezone edge cases | Correct times when traveling |
| 7.5 | Test network failure recovery | Handles offline gracefully |
| 7.6 | Optimize for older iPads | Smooth on iPad Air 2 |
| 7.7 | Fix any discovered issues | All bugs resolved |

**Exit Criteria**: App is stable and ready for daily use.

---

## Parallel Execution Map

```
Week 1:
├── Phase 0 (Project Foundation) ────────────┐
                                              │
Week 2:                                       ▼
├── Phase 1 (API/Data) ──────────────────────┬─→ Phase 3 (Core Logic)
├── Phase 2 (Audio) ─────────────────────────┤
                                              │
Week 3:                                       ▼
├── Phase 4 (Location) ──────────────────────┤
├── Phase 5 (UI) ←───────────────────────────┤
├── Phase 6 (Kiosk Instructions) ────────────┤
                                              │
Week 4:                                       ▼
└── Phase 7 (Integration & Polish) ──────────┘
```

**Parallelizable**:
- Phase 1 + Phase 2 (completely independent)
- Phase 4 + Phase 5 + Phase 6 (mostly independent)

**Sequential Dependencies**:
- Phase 0 → Everything else
- Phase 1 → Phase 3
- Phase 3 → Phase 5 completion (UI needs data to display)

---

## Validation Checkpoints

### Checkpoint A: "Can I build and run?"
After Phase 0: Deploy empty app to iPad via Xcode.

### Checkpoint B: "Does audio work?"
After Phase 2: Play adhan with screen locked. **This is the critical test.**

### Checkpoint C: "Does it fetch prayer times?"
After Phase 1: Console shows correct prayer times for your location.

### Checkpoint D: "Does it auto-play adhan?"
After Phase 3: Set time before prayer, watch adhan trigger automatically.

### Checkpoint E: "Does it look right?"
After Phase 5: UI matches web app, all data displays correctly.

### Checkpoint F: "Is it production-ready?"
After Phase 7: 24-hour test passes, all edge cases handled.

---

## File Structure

```
AdhanApp/
├── AdhanApp.swift                    # @main entry point
├── ContentView.swift                 # Root view controller
│
├── Models/
│   ├── Prayer.swift                  # Prayer struct
│   ├── PrayerSchedule.swift          # Daily schedule
│   └── AlAdhanResponse.swift         # API response models
│
├── Services/
│   ├── AlAdhanService.swift          # API networking
│   ├── LocationService.swift         # CoreLocation wrapper
│   └── AdhanAudioManager.swift       # AVFoundation audio
│
├── ViewModels/
│   └── PrayerTimesManager.swift      # Main business logic
│
├── Views/
│   ├── MainClockView.swift           # Large time display
│   ├── DateHeaderView.swift          # Bismillah + dates
│   ├── PrayerListView.swift          # 5 prayer cards
│   ├── NextPrayerView.swift          # "Next: X @ time"
│   ├── PrayerIndicatorView.swift     # Corner indicator
│   ├── NightOverlayView.swift        # Dimming overlay
│   └── KioskInstructionsView.swift   # First-run setup guide
│
├── Resources/
│   ├── Assets.xcassets/
│   │   ├── mosque.imageset/          # Background image
│   │   └── AppIcon.appiconset/       # App icons
│   └── adhan.mp3                     # Adhan audio file
│
└── Info.plist                        # App configuration
```

---

## Getting Started

### Prerequisites
1. Mac with Xcode 14+ installed (free from Mac App Store)
2. Apple ID (free, for signing)
3. iPad with iOS 15+ for testing
4. USB cable to connect iPad to Mac

### First Steps
1. I will generate the Xcode project structure
2. You open it in Xcode
3. Connect your iPad, select it as the target device
4. Click "Run" - Xcode will prompt you to trust your Apple ID
5. On iPad, go to Settings → General → Device Management → Trust your Apple ID
6. Run again - app should install!

---

## Questions Answered

| Question | Answer |
|----------|--------|
| Do I need Apple Developer account? | **No** - free Apple ID works for personal testing |
| Will it work on my old iPad? | **Yes** - targeting iOS 15 (supports 2014+ iPads) |
| Can phases run in parallel? | **Yes** - see parallel execution map above |
| How do we validate each phase? | Each phase has specific validation tests |
| What's the most critical test? | **Checkpoint B** - audio with screen locked |
