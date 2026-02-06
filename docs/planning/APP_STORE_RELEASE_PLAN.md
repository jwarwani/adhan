# App Store Release Plan: Adhan Prayer Clock

This document outlines the comprehensive plan to prepare the Adhan Prayer Clock app for App Store release.

---

## Table of Contents

1. [Settings Architecture](#1-settings-architecture)
2. [Settings UX Design](#2-settings-ux-design)
3. [Debug Mode Strategy](#3-debug-mode-strategy)
4. [User Feedback & Logging](#4-user-feedback--logging)
5. [App Store Requirements](#5-app-store-requirements)
6. [Implementation Phases](#6-implementation-phases)

---

## 1. Settings Architecture

### Philosophy
Keep settings minimal—just enough to serve diverse Muslim communities without overwhelming users. The app should work perfectly "out of the box" for most users.

### Essential Settings

#### 1.1 Prayer Calculation Method
Different regions and organizations use different astronomical calculations for Fajr and Isha times.

| Method ID | Name | Region/Use |
|-----------|------|------------|
| 2 | ISNA (Islamic Society of North America) | North America (current default) |
| 3 | MWL (Muslim World League) | Europe, Far East |
| 4 | Umm Al-Qura | Saudi Arabia |
| 5 | Egyptian General Authority | Africa, Middle East |
| 1 | University of Islamic Sciences, Karachi | Pakistan, parts of Europe |
| 7 | Institute of Geophysics, Tehran | Iran, Shia communities |

**Implementation:**
```swift
enum CalculationMethod: Int, CaseIterable, Codable {
    case isna = 2
    case mwl = 3
    case ummAlQura = 4
    case egyptian = 5
    case karachi = 1
    case tehran = 7

    var displayName: String { ... }
    var description: String { ... }  // Brief explanation
}
```

#### 1.2 Asr Calculation School
Two valid juristic opinions result in different Asr times (can differ by ~45-60 minutes):

| School | Shadow Factor | Common Regions |
|--------|---------------|----------------|
| Shafi'i/Maliki/Hanbali (Standard) | 1x object height | Most Muslim world |
| Hanafi | 2x object height | South Asia, Turkey |

**Implementation:**
```swift
enum AsrSchool: Int, Codable {
    case standard = 0  // Shafi'i
    case hanafi = 1

    var displayName: String { ... }
}
```

#### 1.3 Location Settings
Allow users to override automatic location detection.

```swift
struct LocationSettings: Codable {
    var useAutomaticLocation: Bool = true
    var manualCity: String?
    var manualCountry: String?
    var manualLatitude: Double?
    var manualLongitude: Double?
}
```

**Options:**
- **Automatic (default):** Use device GPS
- **Manual:** User searches for and selects a city, or enters coordinates

#### 1.4 Adhan Preferences (Per-Prayer Alert Mode)
Users often want different behavior for different prayers (e.g., silent during Fajr when family sleeps, notification-only at work).

Each prayer has three alert options:

| Mode | Behavior |
|------|----------|
| **Adhan** | Full adhan audio plays |
| **Notification** | Visual indicator only (screen highlights, no sound) |
| **Silent** | No alert at all |

```swift
enum PrayerAlertMode: String, CaseIterable, Codable {
    case adhan = "adhan"              // Full adhan audio
    case notification = "notification" // Visual only, no sound
    case silent = "silent"            // No alert

    var displayName: String {
        switch self {
        case .adhan: return "Adhan"
        case .notification: return "Notification"
        case .silent: return "Silent"
        }
    }

    var icon: String {
        switch self {
        case .adhan: return "speaker.wave.3.fill"
        case .notification: return "bell.fill"
        case .silent: return "bell.slash.fill"
        }
    }
}
```

#### 1.5 Audio Files

The app uses the existing adhan audio files in the bundle:

| File | Purpose |
|------|---------|
| `adhan.mp3` | Standard adhan (for Dhuhr, Asr, Maghrib, Isha) |
| `adhan_fajr.mp3` | Fajr-specific adhan (**needs to be obtained**) |

**Why Fajr is different:** The Fajr adhan traditionally includes an additional phrase: "الصلاة خير من النوم" (As-salatu khayrun min an-nawm / "Prayer is better than sleep"). This phrase is only recited in the Fajr adhan.

#### 1.6 Settings Model

```swift
class AppSettings: ObservableObject {
    // Prayer calculation
    @AppStorage("calculationMethod") var calculationMethod: Int = 2
    @AppStorage("asrSchool") var asrSchool: Int = 1

    // Location
    @AppStorage("useAutoLocation") var useAutoLocation: Bool = true
    @AppStorage("manualLatitude") var manualLatitude: Double = 0
    @AppStorage("manualLongitude") var manualLongitude: Double = 0
    @AppStorage("manualCityName") var manualCityName: String = ""

    // Per-prayer alert modes (adhan / notification / silent)
    @AppStorage("alertModeFajr") var alertModeFajr: String = "adhan"
    @AppStorage("alertModeDhuhr") var alertModeDhuhr: String = "adhan"
    @AppStorage("alertModeAsr") var alertModeAsr: String = "adhan"
    @AppStorage("alertModeMaghrib") var alertModeMaghrib: String = "adhan"
    @AppStorage("alertModeIsha") var alertModeIsha: String = "adhan"

    // Convenience methods
    func alertMode(for prayer: String) -> PrayerAlertMode {
        let raw: String
        switch prayer {
        case "Fajr": raw = alertModeFajr
        case "Dhuhr": raw = alertModeDhuhr
        case "Asr": raw = alertModeAsr
        case "Maghrib": raw = alertModeMaghrib
        case "Isha": raw = alertModeIsha
        default: raw = "adhan"
        }
        return PrayerAlertMode(rawValue: raw) ?? .adhan
    }

    func setAlertMode(_ mode: PrayerAlertMode, for prayer: String) {
        switch prayer {
        case "Fajr": alertModeFajr = mode.rawValue
        case "Dhuhr": alertModeDhuhr = mode.rawValue
        case "Asr": alertModeAsr = mode.rawValue
        case "Maghrib": alertModeMaghrib = mode.rawValue
        case "Isha": alertModeIsha = mode.rawValue
        default: break
        }
    }
}
```

### Settings NOT to Include (Keep Simple)
- Volume control (use device volume)
- Multiple adhan reciter options (use existing audio files only)
- Hijri date adjustments
- Custom prayer time offsets
- Themes/colors (keep the unified Islamic aesthetic)
- Language selection (follow device language)

---

## 2. Settings UX Design

### Design Philosophy
Settings should be **discoverable but unobtrusive**—the main clock view remains serene and distraction-free.

### Access Pattern: Subtle Gear Icon

**Location:** Bottom-left corner (opposite the location indicator)

**Visual Treatment:**
- Small gear icon (SF Symbol `gearshape`)
- Low opacity (0.3-0.4) by default
- Slightly larger on tap to indicate interactivity
- Matches the understated aesthetic

```
+------------------------------------------+
|   Bismillah                              |
|   Date                                   |
|                                          |
|           14:32:45                        |
|         Next: Asr 15:45                  |
|                                          |
|  [Fajr] [Dhuhr] [Asr] [Maghrib] [Isha]  |
|                                          |
| [gear]                      Queens, NY   |
+------------------------------------------+
```

### Settings View Design

**Style:** Bottom sheet (`.sheet` modifier) that slides up

**Layout:** Clean, grouped sections

```
+------------------------------------------+
|           Settings                    [X] |
+------------------------------------------+
|                                          |
| PRAYER CALCULATION                       |
| ---------------------------------------- |
| Method            [ISNA (North America)] |
| Asr School                      [Hanafi] |
|                                          |
| LOCATION                                 |
| ---------------------------------------- |
| [x] Use automatic location               |
|     Queens, NY                           |
|                                          |
| PRAYER ALERTS                            |
| ---------------------------------------- |
|                                          |
| Fajr        [🔊 Adhan ▾]                 |
| Dhuhr       [🔊 Adhan ▾]                 |
| Asr         [🔔 Notification ▾]          |
| Maghrib     [🔊 Adhan ▾]                 |
| Isha        [🔊 Adhan ▾]                 |
|                                          |
| ABOUT                                    |
| ---------------------------------------- |
| Send Feedback                        [>] |
| Version 1.0.0                            |
|                                          |
+------------------------------------------+
```

### Implementation

```swift
struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @Binding var isPresented: Bool

    var body: some View {
        NavigationView {
            Form {
                Section("Prayer Calculation") {
                    Picker("Method", selection: $settings.calculationMethod) {
                        ForEach(CalculationMethod.allCases, id: \.rawValue) { method in
                            Text(method.displayName).tag(method.rawValue)
                        }
                    }

                    Picker("Asr School", selection: $settings.asrSchool) {
                        Text("Standard (Shafi'i)").tag(0)
                        Text("Hanafi").tag(1)
                    }
                }

                Section("Location") {
                    Toggle("Use automatic location", isOn: $settings.useAutoLocation)
                    if !settings.useAutoLocation {
                        NavigationLink("Select Location") {
                            LocationSearchView(settings: settings)
                        }
                    }
                }

                Section("Prayer Alerts") {
                    PrayerAlertRow(prayer: "Fajr", mode: $settings.alertModeFajr)
                    PrayerAlertRow(prayer: "Dhuhr", mode: $settings.alertModeDhuhr)
                    PrayerAlertRow(prayer: "Asr", mode: $settings.alertModeAsr)
                    PrayerAlertRow(prayer: "Maghrib", mode: $settings.alertModeMaghrib)
                    PrayerAlertRow(prayer: "Isha", mode: $settings.alertModeIsha)
                }

                Section("About") {
                    NavigationLink("Send Feedback") {
                        FeedbackView()
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.appVersion)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { isPresented = false }
                }
            }
        }
    }
}

struct PrayerAlertRow: View {
    let prayer: String
    @Binding var mode: String

    var currentMode: PrayerAlertMode {
        PrayerAlertMode(rawValue: mode) ?? .adhan
    }

    var body: some View {
        Picker(prayer, selection: $mode) {
            ForEach(PrayerAlertMode.allCases, id: \.rawValue) { alertMode in
                Label(alertMode.displayName, systemImage: alertMode.icon)
                    .tag(alertMode.rawValue)
            }
        }
    }
}
```

---

## 3. Debug Mode Strategy

### Production vs Development

The debug panel should **never** be accessible in App Store builds.

### Implementation Strategy: Compile-Time Flags

```swift
// In ContentView.swift

#if DEBUG
private let isDebugBuildEnabled = true
#else
private let isDebugBuildEnabled = false
#endif

// Only show debug gesture in debug builds
var body: some View {
    MainClockView(...)
        #if DEBUG
        .onTapGesture(count: 3) {
            showDebugPanel.toggle()
        }
        #endif
}
```

### TestFlight Builds (Beta Testing)

For TestFlight testers who need debug access:

```swift
enum BuildEnvironment {
    static var isTestFlight: Bool {
        guard let receiptURL = Bundle.main.appStoreReceiptURL else { return false }
        return receiptURL.lastPathComponent == "sandboxReceipt"
    }

    static var allowDebug: Bool {
        #if DEBUG
        return true
        #else
        return isTestFlight
        #endif
    }
}

// Usage
if BuildEnvironment.allowDebug {
    // Show debug panel option
}
```

### Secret Gesture for Emergency Debug (Optional)

If you want a hidden way to access debug info in production (for support purposes):

```swift
// Shake device + hold two fingers for 3 seconds
@State private var debugUnlockAttempts = 0

.onShake {
    debugUnlockAttempts += 1
    if debugUnlockAttempts >= 5 {
        // Show simplified diagnostic view (not full debug panel)
        showDiagnostics = true
    }
    // Reset after 10 seconds
    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
        debugUnlockAttempts = 0
    }
}
```

### Debug Panel Modifications

Keep full debug panel for DEBUG/TestFlight, but add a simpler "Diagnostics" view for production support:

```swift
struct DiagnosticsView: View {
    // Read-only diagnostics - no triggering adhan, just info
    var body: some View {
        VStack {
            Text("Diagnostics")
            Text("App Version: \(Bundle.main.appVersion)")
            Text("iOS: \(UIDevice.current.systemVersion)")
            Text("Location: \(locationString)")
            Text("Last API fetch: \(lastFetchTime)")
            Text("Prayers loaded: \(prayerCount)")

            Button("Copy to Clipboard") {
                UIPasteboard.general.string = diagnosticString
            }

            Button("Send to Developer") {
                // Opens feedback with diagnostics attached
            }
        }
    }
}
```

---

## 4. User Feedback & Logging

### 4.1 Logging Infrastructure

Implement structured logging that can be included in bug reports.

```swift
import os.log

class AppLogger {
    static let shared = AppLogger()

    private let subsystem = "com.yourname.adhan"

    // Category-specific loggers
    let general: Logger
    let api: Logger
    let audio: Logger
    let location: Logger

    // In-memory log buffer for feedback
    private var logBuffer: [LogEntry] = []
    private let maxBufferSize = 500
    private let queue = DispatchQueue(label: "com.adhan.logger")

    struct LogEntry: Codable {
        let timestamp: Date
        let category: String
        let level: String
        let message: String
    }

    init() {
        general = Logger(subsystem: subsystem, category: "general")
        api = Logger(subsystem: subsystem, category: "api")
        audio = Logger(subsystem: subsystem, category: "audio")
        location = Logger(subsystem: subsystem, category: "location")
    }

    func log(_ message: String, category: String = "general", level: OSLogType = .info) {
        // Log to system
        let logger = Logger(subsystem: subsystem, category: category)
        logger.log(level: level, "\(message)")

        // Also store in buffer for feedback
        queue.async {
            let entry = LogEntry(
                timestamp: Date(),
                category: category,
                level: level.description,
                message: message
            )
            self.logBuffer.append(entry)

            // Trim old entries
            if self.logBuffer.count > self.maxBufferSize {
                self.logBuffer.removeFirst(self.logBuffer.count - self.maxBufferSize)
            }
        }
    }

    func getRecentLogs(count: Int = 100) -> [LogEntry] {
        return queue.sync {
            Array(logBuffer.suffix(count))
        }
    }

    func exportLogsAsString() -> String {
        let formatter = ISO8601DateFormatter()
        return getRecentLogs().map { entry in
            "[\(formatter.string(from: entry.timestamp))] [\(entry.category)] [\(entry.level)] \(entry.message)"
        }.joined(separator: "\n")
    }
}

// Extension for easy logging throughout the app
extension OSLogType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .error: return "ERROR"
        case .fault: return "FAULT"
        default: return "DEFAULT"
        }
    }
}
```

### 4.2 Feedback View

```swift
struct FeedbackView: View {
    @State private var feedbackType: FeedbackType = .bug
    @State private var description = ""
    @State private var includeLogs = true
    @State private var showMailComposer = false

    enum FeedbackType: String, CaseIterable {
        case bug = "Bug Report"
        case feature = "Feature Request"
        case question = "Question"
        case other = "Other"
    }

    var body: some View {
        Form {
            Section {
                Picker("Type", selection: $feedbackType) {
                    ForEach(FeedbackType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
            }

            Section("Description") {
                TextEditor(text: $description)
                    .frame(minHeight: 100)
            }

            Section {
                Toggle("Include diagnostic logs", isOn: $includeLogs)
                Text("Logs help us understand what happened before the issue occurred. They don't contain personal information.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section {
                Button("Send Feedback") {
                    showMailComposer = true
                }
                .disabled(description.isEmpty)
            }

            Section("Device Info") {
                DeviceInfoRow(label: "App Version", value: Bundle.main.appVersion)
                DeviceInfoRow(label: "iOS Version", value: UIDevice.current.systemVersion)
                DeviceInfoRow(label: "Device", value: UIDevice.current.modelName)
            }
        }
        .navigationTitle("Send Feedback")
        .sheet(isPresented: $showMailComposer) {
            MailComposerView(
                recipient: "your-support-email@example.com",
                subject: "[\(feedbackType.rawValue)] Adhan App Feedback",
                body: buildEmailBody()
            )
        }
    }

    private func buildEmailBody() -> String {
        var body = """
        Feedback Type: \(feedbackType.rawValue)

        Description:
        \(description)

        ---
        Device Information:
        App Version: \(Bundle.main.appVersion)
        iOS Version: \(UIDevice.current.systemVersion)
        Device: \(UIDevice.current.modelName)
        Locale: \(Locale.current.identifier)
        Timezone: \(TimeZone.current.identifier)
        """

        if includeLogs {
            body += """

            ---
            Recent Logs:
            \(AppLogger.shared.exportLogsAsString())
            """
        }

        return body
    }
}
```

### 4.3 Mail Composer

```swift
import MessageUI

struct MailComposerView: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    let body: String

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients([recipient])
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        return composer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            dismiss()
        }
    }
}

// Fallback when Mail is not configured
struct FallbackFeedbackView: View {
    let feedbackText: String

    var body: some View {
        VStack(spacing: 20) {
            Text("Mail Not Configured")
                .font(.headline)

            Text("Please copy this information and email it to:")

            Text("support@example.com")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.blue)

            Button("Copy Feedback to Clipboard") {
                UIPasteboard.general.string = feedbackText
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
```

### 4.4 Helper Extensions

```swift
extension Bundle {
    var appVersion: String {
        return "\(infoDictionary?["CFBundleShortVersionString"] as? String ?? "?") (\(infoDictionary?["CFBundleVersion"] as? String ?? "?"))"
    }
}

extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}
```

---

## 5. App Store Requirements

### 5.1 App Store Listing Requirements

| Item | Requirement | Notes |
|------|-------------|-------|
| App Name | Adhan - Prayer Times Clock | Simple, keyword-rich |
| Subtitle | Islamic Prayer Time Display | 30 char max |
| Category | Primary: Lifestyle, Secondary: Reference | |
| Age Rating | 4+ | No objectionable content |
| Price | Free | Consider ads-free premium? |

### 5.2 Screenshots Required

| Device | Orientation | Count | Notes |
|--------|-------------|-------|-------|
| iPhone 6.7" | Portrait | 3-10 | iPhone 15 Pro Max |
| iPhone 6.5" | Portrait | 3-10 | iPhone 11 Pro Max |
| iPhone 5.5" | Portrait | 3-10 | iPhone 8 Plus |
| iPad Pro 12.9" (6th gen) | Landscape | 3-10 | **Primary use case** |
| iPad Pro 12.9" (2nd gen) | Landscape | 3-10 | Older iPad support |

**Screenshot Scenarios:**
1. Main clock view with beautiful mosque background
2. Prayer approaching indicator (🌙 "Prayer soon")
3. Night mode (post-Isha dimming)
4. Settings view (showing calculation options)
5. Ramadan/special date display

### 5.3 Privacy

**Required Privacy Labels:**
- Location: "Used to calculate accurate prayer times for your location"
- No data collected or shared with third parties
- All processing done on-device

**Privacy Policy:** Required. Must explain:
- Location data usage (prayer times only)
- No account required
- No analytics/tracking
- Data stored locally only

### 5.4 Required Assets

| Asset | Size | Format |
|-------|------|--------|
| App Icon | 1024x1024 | PNG, no alpha |
| Launch Screen | Xcode storyboard | Use app background |

### 5.5 Technical Requirements

- **Minimum iOS:** 15.0 (balance between features and reach)
- **Supported Devices:** iPhone, iPad
- **Orientations:** iPad landscape (primary), iPhone portrait
- **Background Modes:** Audio (for adhan playback)
- **Required Device Capabilities:** GPS

---

## 6. Implementation Phases

Phases are organized to **frontload independent tasks** that can be done in parallel or without dependencies.

---

### Phase 0: Audio Asset Acquisition (Do First - Parallel)
**Goal:** Obtain the Fajr-specific adhan audio file

The Fajr adhan is traditionally different from other adhans—it includes the additional phrase:
> **"الصلاة خير من النوم"** (As-salatu khayrun min an-nawm)
> "Prayer is better than sleep"

This phrase is recited twice after "Hayya 'ala al-falah" and is **only** used in the Fajr adhan.

**Action Items:**
- [ ] **Option A:** Record or obtain a royalty-free Fajr adhan audio file
  - Sources: Islamic audio libraries, mosque recordings, professional reciters
  - Ensure the recording includes "As-salatu khayrun min an-nawm"
- [ ] **Option B:** Edit existing adhan to splice in the Fajr phrase
  - Less ideal but workable if recording isn't available
- [ ] Save as `adhan_fajr.mp3` in the Xcode project bundle
- [ ] Verify audio quality matches existing `adhan.mp3`

**Why do this first:** This is a blocking dependency for the audio manager changes. Start sourcing immediately while other development proceeds.

---

### Phase 1: Independent Code Components (Parallel Work)
**Goal:** Build all components that don't depend on each other

These can all be developed simultaneously:

#### 1A: Settings Model & Enums
- [ ] Create `Models/AppSettings.swift`
- [ ] Create `PrayerAlertMode` enum (adhan/notification/silent)
- [ ] Create `CalculationMethod` enum
- [ ] Create `AsrSchool` enum
- [ ] Add @AppStorage properties for all settings

**Files:** `Models/AppSettings.swift`, `Models/Enums/PrayerAlertMode.swift`

#### 1B: Logging Infrastructure
- [ ] Create `Utilities/AppLogger.swift`
- [ ] Implement in-memory log buffer
- [ ] Add category-specific loggers (api, audio, location, general)
- [ ] Create log export function for feedback

**Files:** `Utilities/AppLogger.swift`

#### 1C: Build Environment Utility
- [ ] Create `Utilities/BuildEnvironment.swift`
- [ ] Implement TestFlight detection
- [ ] Add `allowDebug` computed property

**Files:** `Utilities/BuildEnvironment.swift`

#### 1D: Bundle Extensions
- [ ] Create `Extensions/Bundle+Version.swift`
- [ ] Create `Extensions/UIDevice+ModelName.swift`

**Files:** `Extensions/Bundle+Version.swift`, `Extensions/UIDevice+ModelName.swift`

#### 1E: Mail Composer View
- [ ] Create `Views/MailComposerView.swift`
- [ ] Implement UIViewControllerRepresentable wrapper
- [ ] Create fallback view for when Mail isn't configured

**Files:** `Views/MailComposerView.swift`

---

### Phase 2: Audio Manager Updates (Requires Phase 0)
**Goal:** Update audio playback to handle Fajr-specific adhan

**Changes to `AdhanAudioManager.swift`:**

```swift
/// Play the appropriate adhan for a prayer
/// - Parameters:
///   - prayerName: Name of the prayer (used to select Fajr-specific audio)
///   - completion: Called when playback finishes
func playAdhan(for prayerName: String, completion: (() -> Void)? = nil) {
    self.completionHandler = completion

    // Select appropriate audio file
    let audioFileName = (prayerName == "Fajr") ? "adhan_fajr" : "adhan"

    guard let url = Bundle.main.url(forResource: audioFileName, withExtension: "mp3") else {
        // Fallback to standard adhan if Fajr-specific not found
        if prayerName == "Fajr",
           let fallbackURL = Bundle.main.url(forResource: "adhan", withExtension: "mp3") {
            AppLogger.shared.log("Fajr adhan not found, using standard adhan", category: "audio", level: .error)
            playAudioFile(url: fallbackURL)
            return
        }
        AppLogger.shared.log("Adhan audio file not found: \(audioFileName)", category: "audio", level: .fault)
        completion?()
        return
    }

    playAudioFile(url: url)
}

private func playAudioFile(url: URL) {
    do {
        try AVAudioSession.sharedInstance().setActive(true)
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.delegate = self
        audioPlayer?.prepareToPlay()

        let success = audioPlayer?.play() ?? false
        if success {
            isPlaying = true
            AppLogger.shared.log("Adhan playback started: \(url.lastPathComponent)", category: "audio")
        } else {
            AppLogger.shared.log("Adhan playback failed to start", category: "audio", level: .error)
            completionHandler?()
        }
    } catch {
        AppLogger.shared.log("Audio player error: \(error)", category: "audio", level: .error)
        completionHandler?()
    }
}
```

**Action Items:**
- [ ] Add `adhan_fajr.mp3` to Xcode project bundle
- [ ] Modify `playAdhan()` to accept prayer name parameter
- [ ] Implement Fajr-specific audio selection
- [ ] Add fallback logic if Fajr audio missing
- [ ] Add logging throughout

**Files:** `Services/AdhanAudioManager.swift`

---

### Phase 3: Settings UI (Requires Phase 1A)
**Goal:** Build settings views

- [ ] Create `Views/SettingsView.swift` with Form layout
- [ ] Create `PrayerAlertRow` component for per-prayer picker
- [ ] Create `Views/LocationSearchView.swift` for manual location
- [ ] Create `Views/FeedbackView.swift`
- [ ] Add settings gear icon to `ContentView.swift`
- [ ] Wire up settings sheet presentation

**Files:**
- `Views/SettingsView.swift` (new)
- `Views/PrayerAlertRow.swift` (new)
- `Views/LocationSearchView.swift` (new)
- `Views/FeedbackView.swift` (new)
- `ContentView.swift` (modify)

---

### Phase 4: Integration (Requires Phases 1-3)
**Goal:** Connect all components

#### 4A: Wire Settings to API Service
- [ ] Modify `AlAdhanService` to accept calculation method and school
- [ ] Update API URL construction to use settings
- [ ] Add settings observation to trigger refresh on change

**Files:** `Services/AlAdhanService.swift`

#### 4B: Wire Settings to Prayer Manager
- [ ] Inject `AppSettings` into `PrayerTimesManager`
- [ ] Check alert mode before playing adhan
- [ ] Pass prayer name to audio manager for Fajr detection
- [ ] Handle "notification" mode (visual only)
- [ ] Handle "silent" mode (no alert)

```swift
private func handlePrayerTime(for prayer: Prayer) {
    let alertMode = settings.alertMode(for: prayer.name)

    switch alertMode {
    case .adhan:
        playAdhan(for: prayer)
    case .notification:
        showVisualNotification(for: prayer)
        // No audio
    case .silent:
        // Do nothing, just advance to next prayer
        break
    }

    advanceToNextPrayer()
}

private func playAdhan(for prayer: Prayer) {
    isAdhanPlaying = true
    audioManager.playAdhan(for: prayer.name) { [weak self] in
        Task { @MainActor in
            self?.isAdhanPlaying = false
        }
    }
}
```

**Files:** `ViewModels/PrayerTimesManager.swift`

#### 4C: Add Logging Throughout
- [ ] Add logging to `AlAdhanService` (API calls, errors)
- [ ] Add logging to `LocationService` (permission, updates)
- [ ] Add logging to `AdhanAudioManager` (playback events)
- [ ] Add logging to `PrayerTimesManager` (state changes)

---

### Phase 5: Debug Mode Cleanup (Requires Phase 1C)
**Goal:** Hide debug features from production

- [ ] Add `#if DEBUG` guards around debug panel in `ContentView.swift`
- [ ] Create `DiagnosticsView.swift` for production support
- [ ] Remove/guard all `print()` statements in release builds
- [ ] Test that debug panel is inaccessible in release builds
- [ ] Verify TestFlight builds have limited debug access

**Files:**
- `ContentView.swift` (modify)
- `Views/DiagnosticsView.swift` (new)
- All files with `print()` statements

---

### Phase 6: Polish & Assets
**Goal:** Prepare App Store assets

- [ ] Create app icon (1024x1024)
- [ ] Design launch screen
- [ ] Capture screenshots for all required devices
- [ ] Write App Store description and keywords
- [ ] Draft privacy policy
- [ ] Create promotional text

---

### Phase 7: Testing & Submission
**Goal:** Final testing and App Store submission

- [ ] Full testing pass on multiple devices
- [ ] Test all calculation methods produce valid times
- [ ] Test all alert modes (adhan/notification/silent)
- [ ] Verify Fajr plays correct adhan
- [ ] TestFlight beta with external testers
- [ ] Address beta feedback
- [ ] Submit for App Store review
- [ ] Respond to any review feedback

---

## Implementation Dependency Graph

```
Phase 0 (Audio Asset) ─────────────────────────────┐
                                                   │
Phase 1A (Settings Model) ──┬── Phase 3 (Settings UI)
                            │           │
Phase 1B (Logging) ─────────┤           │
                            │           │
Phase 1C (Build Env) ───────┤           ├── Phase 4 (Integration) ── Phase 5 ── Phase 6 ── Phase 7
                            │           │
Phase 1D (Extensions) ──────┤           │
                            │           │
Phase 1E (Mail Composer) ───┴───────────┘
                                        │
Phase 2 (Audio Manager) ────────────────┘
         (needs Phase 0)
```

**Parallel Tracks:**
- Track A: Phases 1A-1E (all independent, do in parallel)
- Track B: Phase 0 → Phase 2 (audio file → audio manager)
- Then: Phase 3 → Phase 4 → Phase 5 → Phase 6 → Phase 7

---

## Summary

### Settings Added
| Setting | Options | Default |
|---------|---------|---------|
| Calculation Method | ISNA, MWL, Umm Al-Qura, Egyptian, Karachi, Tehran | ISNA |
| Asr School | Standard (Shafi'i), Hanafi | Hanafi |
| Location Mode | Automatic GPS, Manual city | Automatic |
| Per-Prayer Alert | Adhan, Notification, Silent | All Adhan |

### Audio Files
| File | Purpose |
|------|---------|
| `adhan.mp3` | Standard adhan (Dhuhr, Asr, Maghrib, Isha) |
| `adhan_fajr.mp3` | Fajr adhan with "Prayer is better than sleep" |

### UX Changes
- Subtle gear icon in bottom-left for settings access
- Bottom sheet settings panel matching app aesthetic
- Per-prayer alert mode picker (Adhan/Notification/Silent)
- Feedback option in settings with log attachment

### Debug Strategy
- Full debug panel: DEBUG builds only
- Limited diagnostics: TestFlight builds
- No debug access: App Store builds

### Feedback System
- In-app feedback form
- Automatic device/app info collection
- Optional diagnostic log attachment
- Email-based submission

---

*Document created for Adhan Prayer Clock App Store release planning*
