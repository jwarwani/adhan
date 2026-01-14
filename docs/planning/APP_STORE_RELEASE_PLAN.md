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

#### 1.4 Adhan Preferences (Per-Prayer Toggle)
Users often want different behavior for different prayers (e.g., silent during Fajr when family sleeps).

```swift
struct AdhanPreferences: Codable {
    var fajrEnabled: Bool = true
    var dhuhrEnabled: Bool = true
    var asrEnabled: Bool = true
    var maghribEnabled: Bool = true
    var ishaEnabled: Bool = true

    // Which adhan sound to use
    var adhanSound: AdhanSound = .standard
}

enum AdhanSound: String, CaseIterable, Codable {
    case standard = "adhan"           // Current full adhan
    case makkah = "adhan_makkah"      // Makkah-style
    case silent = "silent"            // Visual notification only

    var displayName: String { ... }
}
```

#### 1.5 Settings Model

```swift
class AppSettings: ObservableObject {
    @AppStorage("calculationMethod") var calculationMethod: Int = 2
    @AppStorage("asrSchool") var asrSchool: Int = 1
    @AppStorage("useAutoLocation") var useAutoLocation: Bool = true
    @AppStorage("manualLatitude") var manualLatitude: Double = 0
    @AppStorage("manualLongitude") var manualLongitude: Double = 0
    @AppStorage("manualCityName") var manualCityName: String = ""

    // Per-prayer adhan toggles
    @AppStorage("adhanFajr") var adhanFajr: Bool = true
    @AppStorage("adhanDhuhr") var adhanDhuhr: Bool = true
    @AppStorage("adhanAsr") var adhanAsr: Bool = true
    @AppStorage("adhanMaghrib") var adhanMaghrib: Bool = true
    @AppStorage("adhanIsha") var adhanIsha: Bool = true

    @AppStorage("adhanSound") var adhanSound: String = "adhan"
}
```

### Settings NOT to Include (Keep Simple)
- Volume control (use device volume)
- Custom notification sounds beyond 2-3 options
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
| ADHAN                                    |
| ---------------------------------------- |
| Sound                        [Standard]  |
|                                          |
| Play adhan for:                          |
| Fajr      [ON]                           |
| Dhuhr     [ON]                           |
| Asr       [ON]                           |
| Maghrib   [ON]                           |
| Isha      [ON]                           |
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

                Section("Adhan") {
                    Picker("Sound", selection: $settings.adhanSound) {
                        Text("Standard").tag("adhan")
                        Text("Makkah Style").tag("adhan_makkah")
                        Text("Silent").tag("silent")
                    }

                    Toggle("Fajr", isOn: $settings.adhanFajr)
                    Toggle("Dhuhr", isOn: $settings.adhanDhuhr)
                    Toggle("Asr", isOn: $settings.adhanAsr)
                    Toggle("Maghrib", isOn: $settings.adhanMaghrib)
                    Toggle("Isha", isOn: $settings.adhanIsha)
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

### Phase 1: Core Settings (Week 1-2)
**Goal:** Add essential user-configurable settings

- [ ] Create `AppSettings` class with @AppStorage properties
- [ ] Implement `SettingsView` with calculation method picker
- [ ] Add Asr school selector
- [ ] Create per-prayer adhan toggles
- [ ] Wire settings to `AlAdhanService` API calls
- [ ] Add settings gear icon to main view
- [ ] Test settings persistence across app launches

**Files to create/modify:**
- `Models/AppSettings.swift` (new)
- `Views/SettingsView.swift` (new)
- `Views/LocationSearchView.swift` (new)
- `Services/AlAdhanService.swift` (modify)
- `ViewModels/PrayerTimesManager.swift` (modify)
- `ContentView.swift` (add settings button)

### Phase 2: Debug Mode Cleanup (Week 2)
**Goal:** Hide debug features from production

- [ ] Add `#if DEBUG` guards around debug panel
- [ ] Implement `BuildEnvironment` for TestFlight detection
- [ ] Create simplified `DiagnosticsView` for production support
- [ ] Remove/guard all `print()` statements in release builds
- [ ] Test that debug panel is inaccessible in release builds

**Files to modify:**
- `ContentView.swift`
- `ViewModels/PrayerTimesManager.swift`
- `Utilities/BuildEnvironment.swift` (new)

### Phase 3: Logging & Feedback (Week 2-3)
**Goal:** Enable users to report issues with context

- [ ] Implement `AppLogger` with in-memory buffer
- [ ] Add logging throughout key code paths (API, audio, location)
- [ ] Create `FeedbackView` with email composition
- [ ] Implement `MailComposerView` with UIKit bridge
- [ ] Add "Send Feedback" option in Settings
- [ ] Test feedback flow on device

**Files to create:**
- `Utilities/AppLogger.swift` (new)
- `Views/FeedbackView.swift` (new)
- `Views/MailComposerView.swift` (new)

### Phase 4: Polish & Assets (Week 3-4)
**Goal:** Prepare App Store assets and polish

- [ ] Create app icon (1024x1024)
- [ ] Design launch screen
- [ ] Capture screenshots for all required devices
- [ ] Write App Store description and keywords
- [ ] Draft privacy policy
- [ ] Create promotional text

### Phase 5: Testing & Submission (Week 4-5)
**Goal:** Final testing and App Store submission

- [ ] Full testing pass on multiple devices
- [ ] TestFlight beta with external testers
- [ ] Address beta feedback
- [ ] Submit for App Store review
- [ ] Respond to any review feedback

---

## Summary

### Settings Added
| Setting | Purpose | Default |
|---------|---------|---------|
| Calculation Method | Different regions use different astronomical calculations | ISNA |
| Asr School | Hanafi vs Standard timing | Hanafi |
| Location Mode | Auto GPS vs manual city | Auto |
| Per-Prayer Adhan | Enable/disable adhan per prayer | All on |
| Adhan Sound | Sound selection | Standard |

### UX Changes
- Subtle gear icon in bottom-left for settings access
- Bottom sheet settings panel matching app aesthetic
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
