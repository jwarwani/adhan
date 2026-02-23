import SwiftUI

struct ContentView: View {
    @StateObject private var prayerManager = PrayerTimesManager()
    @StateObject private var settings = AppSettings.shared
    @State private var showKioskInstructions = false
    @State private var showSettings = false
    @AppStorage("hasSeenKioskInstructions") private var hasSeenInstructions = false

    // Debug panel only available in debug/TestFlight builds
    #if DEBUG
    @State private var showDebugPanel = false
    #endif

    // Gold accent color
    private let goldColor = Color(red: 0.85, green: 0.65, blue: 0.13)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background image
                Image("mosque")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()

                // Dark overlay for readability
                Color.black.opacity(0.6)
                    .ignoresSafeArea()

                // Main content
                VStack(spacing: 0) {
                    // Header with dates
                    DateHeaderView(
                        gregorianDate: prayerManager.gregorianDate,
                        hijriDate: prayerManager.hijriDate,
                        screenWidth: geometry.size.width
                    )
                    .padding(.top, 40 * (geometry.size.width / 1180))

                    Spacer()

                    // Large clock display
                    MainClockView(
                        currentTime: prayerManager.currentTime,
                        screenWidth: geometry.size.width
                    )
                    #if DEBUG
                    // Triple-tap for debug mode (only in debug builds)
                    .onTapGesture(count: 3) {
                        showDebugPanel.toggle()
                    }
                    #endif

                    // Next prayer indicator
                    NextPrayerView(
                        prayer: prayerManager.focusedPrayer,
                        currentTime: prayerManager.currentTime,
                        screenWidth: geometry.size.width
                    )
                    .padding(.top, 20 * (geometry.size.width / 1180))

                    Spacer()

                    // Prayer times grid
                    PrayerListView(
                        prayers: prayerManager.prayers,
                        focusedPrayer: prayerManager.focusedPrayer,
                        isApproaching: prayerManager.isApproaching,
                        isActive: prayerManager.isActive,
                        screenWidth: geometry.size.width
                    )
                    .padding(.horizontal, 40 * (geometry.size.width / 1180))
                    .padding(.bottom, 40 * (geometry.size.width / 1180))
                }

                // Settings button (bottom left)
                VStack {
                    Spacer()
                    HStack {
                        let scale = geometry.size.width / 1180
                        Button(action: { showSettings = true }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 18 * scale))
                                .foregroundColor(.white.opacity(0.4))
                                .padding(12 * scale)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .padding(.leading, 20 * scale)
                        .padding(.bottom, 20 * scale)
                        Spacer()
                    }
                }

                // Location indicator (bottom right)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        let scale = geometry.size.width / 1180
                        HStack(spacing: 6 * scale) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 12 * scale))
                            Text(prayerManager.locationName)
                                .font(.system(size: 14 * scale))
                        }
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 16 * scale)
                        .padding(.vertical, 8 * scale)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(20 * scale)
                        .padding(.trailing, 20 * scale)
                        .padding(.bottom, 20 * scale)
                    }
                }

                // Loading indicator
                if prayerManager.isLoading {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        Text("Loading prayer times...")
                            .foregroundColor(.white)
                            .padding(.top, 10)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.7))
                }

                // Night mode overlay
                NightOverlayView(isNightMode: prayerManager.isNightMode)

                // Visual notification overlay (for notification-only mode)
                if prayerManager.showPrayerNotification {
                    PrayerNotificationOverlay(
                        prayerName: prayerManager.notificationPrayerName,
                        onDismiss: {
                            prayerManager.dismissNotification()
                        }
                    )
                }

                // Debug panel (only in debug/TestFlight builds)
                #if DEBUG
                if showDebugPanel {
                    DebugPanelView(
                        prayerManager: prayerManager,
                        isPresented: $showDebugPanel
                    )
                }
                #endif

                // Kiosk instructions overlay
                if showKioskInstructions {
                    KioskInstructionsView(isPresented: $showKioskInstructions)
                }

                // Error indicator
                if let error = prayerManager.errorMessage {
                    VStack {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(error)
                                .foregroundColor(.white)
                            Button("Retry") {
                                Task {
                                    await prayerManager.refresh()
                                }
                            }
                            .foregroundColor(goldColor)
                        }
                        .font(.system(size: 14))
                        .padding(12)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(8)
                        Spacer()
                    }
                    .padding(.top, 20)
                }
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showSettings) {
            SettingsView(settings: settings, isPresented: $showSettings)
        }
        .onChange(of: settings.calculationMethod) { _ in
            // Refresh prayer times when calculation method changes
            Task { await prayerManager.refresh() }
        }
        .onChange(of: settings.asrSchool) { _ in
            // Refresh prayer times when Asr school changes
            Task { await prayerManager.refresh() }
        }
        .onChange(of: settings.useAutoLocation) { _ in
            // Refresh prayer times when location mode changes
            Task { await prayerManager.refresh() }
        }
        .onAppear {
            // Keep screen always on for kiosk mode
            UIApplication.shared.isIdleTimerDisabled = true

            // Show kiosk instructions on first launch
            if !hasSeenInstructions {
                showKioskInstructions = true
            }

            AppLogger.shared.info("App appeared, screen lock disabled", category: "general")
        }
    }
}

// MARK: - Prayer Notification Overlay

/// Visual notification overlay shown when alert mode is "notification"
struct PrayerNotificationOverlay: View {
    let prayerName: String
    let onDismiss: () -> Void

    // Gold accent color
    private let goldColor = Color(red: 0.85, green: 0.65, blue: 0.13)

    var body: some View {
        VStack(spacing: 24) {
            // Bell icon
            Image(systemName: "bell.fill")
                .font(.system(size: 60))
                .foregroundColor(goldColor)

            // Prayer name
            Text("\(prayerName) Time")
                .font(.system(size: 36, weight: .bold, design: .serif))
                .foregroundColor(.white)

            // Dismiss button
            Button(action: onDismiss) {
                Text("Dismiss")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(goldColor)
                    .cornerRadius(25)
            }
            .padding(.top, 16)
        }
        .padding(48)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.9))
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.5))
    }
}

// MARK: - Debug Panel

#if DEBUG
struct DebugPanelView: View {
    @ObservedObject var prayerManager: PrayerTimesManager
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Debug Panel")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            Divider().background(Color.white.opacity(0.3))

            // Build info
            Text("Build: \(BuildEnvironment.configurationName)")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))

            // Focused prayer info
            if let focused = prayerManager.focusedPrayer {
                Text("Focused: \(focused.name) @ \(focused.formattedTime)")
                    .foregroundColor(.white.opacity(0.8))

                let alertMode = AppSettings.shared.alertMode(for: focused.name)
                Text("Alert Mode: \(alertMode.displayName)")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.system(size: 14))

                Text("Approaching: \(prayerManager.isApproaching ? "Yes" : "No"), Active: \(prayerManager.isActive ? "Yes" : "No")")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.system(size: 14))
            } else {
                Text("No upcoming prayer today")
                    .foregroundColor(.white.opacity(0.8))
            }

            // Trigger adhan button
            Button(action: {
                prayerManager.triggerAdhanNow()
            }) {
                HStack {
                    Image(systemName: "speaker.wave.3.fill")
                    Text("Trigger Adhan Now")
                }
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.green)
                .cornerRadius(10)
            }

            // Simulate next prayer time
            Button(action: {
                prayerManager.simulateNextPrayerTime()
            }) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("Simulate Prayer Time Reached")
                }
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.orange)
                .cornerRadius(10)
            }

            // Stop adhan button
            Button(action: {
                prayerManager.stopAdhan()
            }) {
                HStack {
                    Image(systemName: "stop.fill")
                    Text("Stop Adhan")
                }
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.red)
                .cornerRadius(10)
            }

            Text("Triple-tap clock to toggle this panel")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.9))
        )
        .frame(maxWidth: 400)
        .padding(40)
    }
}
#endif

#Preview {
    ContentView()
}
