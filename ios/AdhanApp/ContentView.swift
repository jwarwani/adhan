import SwiftUI

struct ContentView: View {
    @StateObject private var prayerManager = PrayerTimesManager()
    @State private var showKioskInstructions = false
    @State private var showDebugPanel = false
    @AppStorage("hasSeenKioskInstructions") private var hasSeenInstructions = false

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
                        hijriDate: prayerManager.hijriDate
                    )
                    .padding(.top, 40)

                    Spacer()

                    // Large clock display (triple-tap for debug mode)
                    MainClockView(currentTime: prayerManager.currentTime)
                        .onTapGesture(count: 3) {
                            showDebugPanel.toggle()
                        }

                    // Next prayer indicator
                    NextPrayerView(
                        prayer: prayerManager.nextPrayer,
                        currentTime: prayerManager.currentTime
                    )
                    .padding(.top, 20)

                    Spacer()

                    // Prayer times grid
                    PrayerListView(
                        prayers: prayerManager.prayers,
                        nextPrayer: prayerManager.nextPrayer,
                        approachingPrayer: prayerManager.approachingPrayer,
                        isAdhanPlaying: prayerManager.isAdhanPlaying
                    )
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }

                // Location indicator (bottom right)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 12))
                            Text(prayerManager.locationName)
                                .font(.system(size: 14))
                        }
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(20)
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
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

                // Debug panel (triple-tap clock to show)
                if showDebugPanel {
                    DebugPanelView(
                        prayerManager: prayerManager,
                        isPresented: $showDebugPanel
                    )
                }

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
        .onAppear {
            // Keep screen always on for kiosk mode
            UIApplication.shared.isIdleTimerDisabled = true

            // Show kiosk instructions on first launch
            if !hasSeenInstructions {
                showKioskInstructions = true
            }
        }
    }
}

// MARK: - Debug Panel

struct DebugPanelView: View {
    @ObservedObject var prayerManager: PrayerTimesManager
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("🛠 Debug Panel")
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

            // Next prayer info
            if let next = prayerManager.nextPrayer {
                Text("Next: \(next.name) @ \(next.formattedTime)")
                    .foregroundColor(.white.opacity(0.8))
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

#Preview {
    ContentView()
}
