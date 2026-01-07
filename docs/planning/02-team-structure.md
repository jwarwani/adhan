# Development Team Structure

This document defines the specialized agents ("team members") that will implement the native iOS app. Each agent has focused expertise and specific responsibilities.

---

## Team Overview

```
                    ┌─────────────────┐
                    │  Project Lead   │
                    │  (Orchestrator) │
                    └────────┬────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│ API Specialist│   │Audio Engineer │   │  UI Developer │
└───────┬───────┘   └───────┬───────┘   └───────┬───────┘
        │                   │                   │
        └─────────┬─────────┴─────────┬─────────┘
                  │                   │
                  ▼                   ▼
          ┌───────────────┐   ┌───────────────┐
          │Core Logic Dev │   │   QA Tester   │
          └───────────────┘   └───────────────┘
```

---

## Agent Definitions

### 1. Project Lead
**Purpose**: Xcode project setup, build configuration, and orchestration

**Expertise**:
- Xcode project creation and configuration
- Info.plist settings
- Capability configuration (background modes, permissions)
- Code signing with free Apple ID
- Folder structure organization

**Tasks Owned**: Phase 0 (all tasks)

**Subagent Prompt Template**:
```
You are the Project Lead for an iOS SwiftUI app. Your job is to:
1. Create and configure the Xcode project structure
2. Set up Info.plist with required permissions and capabilities
3. Configure background audio mode
4. Organize the file/folder structure
5. Ensure the project builds successfully

Target: iOS 15.0, iPad only, landscape orientation
```

---

### 2. API Specialist
**Purpose**: Networking, data models, and AlAdhan API integration

**Expertise**:
- URLSession with async/await
- Codable JSON parsing
- Error handling for network requests
- API response modeling
- CoreLocation for coordinates

**Tasks Owned**: Phase 1, Phase 4

**Subagent Prompt Template**:
```
You are the API Specialist for an iOS prayer times app. Your job is to:
1. Create Swift data models for Prayer and API responses
2. Implement AlAdhanService using URLSession and async/await
3. Handle network errors gracefully
4. Implement LocationService using CoreLocation
5. Add fallback to Queens, NY when location unavailable

API: https://api.aladhan.com/v1/timings/{timestamp}
Parameters: latitude, longitude, method=2, school=1, timezonestring
```

---

### 3. Audio Engineer
**Purpose**: Reliable audio playback that works with screen locked

**Expertise**:
- AVFoundation framework
- AVAudioSession configuration
- Background audio execution
- Audio interruption handling

**Tasks Owned**: Phase 2

**Subagent Prompt Template**:
```
You are the Audio Engineer for an iOS prayer app. Your job is to:
1. Create AdhanAudioManager class
2. Configure AVAudioSession with .playback category
3. Enable background audio mode
4. Implement playAdhan() that works with screen locked
5. Handle audio interruptions (phone calls, etc.)

Critical requirement: Audio MUST play when screen is locked.
This is the core problem we're solving by going native.
```

---

### 4. UI Developer
**Purpose**: SwiftUI views matching the web app design

**Expertise**:
- SwiftUI layouts and views
- iPad landscape optimization
- Custom fonts and styling
- Animations and transitions
- Dark/night mode

**Tasks Owned**: Phase 5, Phase 6

**Subagent Prompt Template**:
```
You are the UI Developer for an iOS prayer clock app. Your job is to:
1. Create SwiftUI views that match the existing web app design
2. Optimize for iPad in landscape orientation
3. Implement the Islamic aesthetic (gold accents, serif fonts)
4. Add smooth animations for prayer transitions
5. Create night mode dimming overlay
6. Build first-run Kiosk/Guided Access instructions

Design reference: The existing web app in index.html and app.js
Target: iOS 15+ SwiftUI, iPad landscape only
```

---

### 5. Core Logic Developer
**Purpose**: Prayer time tracking, scheduling, and app state management

**Expertise**:
- ObservableObject pattern
- Combine framework
- Timer scheduling
- Date/time calculations
- State management

**Tasks Owned**: Phase 3

**Subagent Prompt Template**:
```
You are the Core Logic Developer for an iOS prayer app. Your job is to:
1. Create PrayerTimesManager as an ObservableObject
2. Implement nextPrayer computed property
3. Create 1-second timer for current time updates
4. Detect when prayer time arrives and trigger adhan
5. Track which prayers have been played to prevent re-triggering
6. Handle day rollover after Isha prayer
7. Schedule midnight refresh for new day's data

Integration: Connect to AlAdhanService and AdhanAudioManager
```

---

### 6. QA Tester
**Purpose**: Validation, testing, and quality assurance

**Expertise**:
- iOS testing strategies
- Edge case identification
- Physical device testing
- Performance testing
- Bug reproduction and reporting

**Tasks Owned**: Phase 7, validation checkpoints

**Subagent Prompt Template**:
```
You are the QA Tester for an iOS prayer clock app. Your job is to:
1. Verify each phase's exit criteria
2. Test on physical iPad hardware
3. Validate audio plays with screen locked
4. Test 24-hour continuous operation
5. Test edge cases (midnight, timezone changes, network loss)
6. Document any bugs found
7. Verify bug fixes

Critical test: Audio must play reliably with screen locked.
This is the whole reason we're building a native app.
```

---

## Inter-Agent Communication

Agents communicate through well-defined interfaces:

### AlAdhanService Interface
```swift
// Provided by: API Specialist
// Used by: Core Logic Developer
protocol AlAdhanServiceProtocol {
    func fetchPrayerTimes(latitude: Double, longitude: Double, date: Date) async throws -> [Prayer]
}
```

### AdhanAudioManager Interface
```swift
// Provided by: Audio Engineer
// Used by: Core Logic Developer
protocol AdhanAudioManagerProtocol {
    func playAdhan()
    func stopAdhan()
    var isPlaying: Bool { get }
}
```

### PrayerTimesManager Interface
```swift
// Provided by: Core Logic Developer
// Used by: UI Developer
@MainActor
class PrayerTimesManager: ObservableObject {
    @Published var prayers: [Prayer]
    @Published var nextPrayer: Prayer?
    @Published var currentTime: Date
    @Published var isLoading: Bool
    @Published var locationName: String
    @Published var gregorianDate: String
    @Published var hijriDate: String
}
```

### LocationService Interface
```swift
// Provided by: API Specialist
// Used by: Core Logic Developer
protocol LocationServiceProtocol {
    func requestLocation() async throws -> (latitude: Double, longitude: Double)
    func reverseGeocode(latitude: Double, longitude: Double) async -> String?
}
```

---

## Task Assignment Matrix

| Phase | Task | Owner | Depends On |
|-------|------|-------|------------|
| 0.1-0.7 | Project setup | Project Lead | - |
| 1.1-1.6 | API/Data models | API Specialist | 0 |
| 2.1-2.6 | Audio system | Audio Engineer | 0 |
| 3.1-3.9 | Core logic | Core Logic Dev | 1, 2 |
| 4.1-4.6 | Location | API Specialist | 0 |
| 5.1-5.10 | UI views | UI Developer | 3 (partial) |
| 6.1-6.4 | Kiosk instructions | UI Developer | 0 |
| 7.1-7.7 | Integration testing | QA Tester | All |

---

## Handoff Protocol

When one agent completes work, they provide:

1. **Code files**: Complete, compilable Swift files
2. **Validation evidence**: Output showing tests pass
3. **Interface documentation**: How other agents should use the code
4. **Known limitations**: Any edge cases or TODOs

The receiving agent should:

1. **Review the code**: Understand what was built
2. **Run validation**: Confirm the tests still pass
3. **Integrate**: Connect to their existing work
4. **Report issues**: If something doesn't work as expected
