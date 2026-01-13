import SwiftUI

struct ContentView: View {
    @StateObject private var prayerManager = PrayerTimesManager()
    @State private var showKioskInstructions = false
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

                    // Large clock display
                    MainClockView(currentTime: prayerManager.currentTime)

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
                        nextPrayer: prayerManager.nextPrayer
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

#Preview {
    ContentView()
}
