import Foundation
import Combine

/// Main state manager for prayer times and app logic
@MainActor
class PrayerTimesManager: ObservableObject {

    // MARK: - Published State

    @Published var prayers: [Prayer] = []
    @Published var focusedPrayer: Prayer?  // The prayer shown in countdown and with indicator
    @Published var currentTime = Date()
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Date display
    @Published var gregorianDate = ""
    @Published var hijriDate = ""
    @Published var locationName = "Loading..."

    // Night mode (after Isha until Fajr)
    @Published var isNightMode = false

    // Adhan playing state
    @Published var isAdhanPlaying = false

    // Derived indicator states based on focusedPrayer
    var isApproaching: Bool {
        guard let focused = focusedPrayer else { return false }
        let timeUntil = focused.time.timeIntervalSince(currentTime)
        // Approaching if within 15 minutes (900 seconds) and not yet reached
        return timeUntil > 0 && timeUntil <= 900
    }

    var isActive: Bool {
        guard focusedPrayer != nil else { return false }
        // Active when adhan is playing (prayer time has been reached)
        return isAdhanPlaying
    }

    // For backward compatibility with NextPrayerView
    var nextPrayer: Prayer? {
        return focusedPrayer
    }

    // MARK: - Private

    private var timer: AnyCancellable?
    private var playedPrayers: Set<String> = []
    private var currentPrayerIndex = 0
    private var hasFetchedTomorrow = false

    private let audioManager = AdhanAudioManager.shared
    private let locationService = LocationService.shared
    private let apiService = AlAdhanService.shared

    // MARK: - Initialization

    init() {
        // Start with sample data while loading
        prayers = Prayer.samples
        updateFocusedPrayer()

        // Start the timer
        startTimer()

        // Load data
        Task {
            await loadPrayerTimes()
        }

        // Schedule midnight refresh
        scheduleMidnightRefresh()
    }

    // MARK: - Data Loading

    /// Load prayer times from API
    func loadPrayerTimes() async {
        isLoading = true
        errorMessage = nil

        // Get location first
        await locationService.requestLocation()
        locationName = locationService.cityName

        do {
            let result = try await apiService.fetchPrayerTimes(
                latitude: locationService.latitude,
                longitude: locationService.longitude
            )

            prayers = result.prayers
            gregorianDate = result.gregorianDate
            hijriDate = result.hijriDate

            updateFocusedPrayer()
            updateNightMode()

            print("PrayerTimesManager: Loaded \(prayers.count) prayers")

        } catch {
            errorMessage = error.localizedDescription
            print("PrayerTimesManager: Error loading prayers - \(error)")
        }

        isLoading = false
    }

    /// Fetch tomorrow's prayer times (called after Isha)
    private func fetchTomorrowPrayers() async {
        guard !hasFetchedTomorrow else { return }
        hasFetchedTomorrow = true

        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

        do {
            let result = try await apiService.fetchPrayerTimes(
                latitude: locationService.latitude,
                longitude: locationService.longitude,
                date: tomorrow
            )

            // Store for tomorrow - will be used after midnight
            print("PrayerTimesManager: Pre-fetched tomorrow's prayers")

            // After midnight refresh, these will become today's prayers
        } catch {
            print("PrayerTimesManager: Failed to fetch tomorrow - \(error)")
        }
    }

    // MARK: - Timer

    /// Start the 1-second timer for time updates and prayer checking
    func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.tick()
                }
            }
    }

    /// Called every second
    private func tick() {
        currentTime = Date()
        checkPrayerTime()
        checkDayRollover()
    }

    // MARK: - Prayer Time Detection

    /// Check if it's time to play adhan
    private func checkPrayerTime() {
        guard let focused = focusedPrayer else { return }

        // Check if current time has reached or passed the prayer time
        if currentTime >= focused.time {
            let prayerKey = makePrayerKey(focused)

            // Only play if we haven't played this prayer today
            if !playedPrayers.contains(prayerKey) {
                playedPrayers.insert(prayerKey)
                playAdhan(for: focused)
                // Note: advanceToNextPrayer is called when adhan FINISHES, not here
            }
        }
    }

    /// Play adhan for a prayer
    private func playAdhan(for prayer: Prayer) {
        print("PrayerTimesManager: Playing adhan for \(prayer.name)")
        isAdhanPlaying = true
        audioManager.playAdhan { [weak self] in
            Task { @MainActor in
                self?.isAdhanPlaying = false
                // Advance to next prayer AFTER adhan finishes
                self?.advanceToNextPrayer()
            }
        }
    }

    /// Advance to the next prayer in the schedule
    private func advanceToNextPrayer() {
        currentPrayerIndex += 1

        if currentPrayerIndex < prayers.count {
            focusedPrayer = prayers[currentPrayerIndex]
            updateNightMode()
        } else {
            // All prayers done for today, next is Fajr tomorrow
            focusedPrayer = nil

            // Fetch tomorrow's times
            Task {
                await fetchTomorrowPrayers()
            }
        }
    }

    /// Update which prayer is focused based on current time
    private func updateFocusedPrayer() {
        let now = Date()

        // Find the next upcoming prayer
        for (index, prayer) in prayers.enumerated() {
            if prayer.time > now {
                currentPrayerIndex = index
                focusedPrayer = prayer
                return
            }
        }

        // All prayers have passed for today
        currentPrayerIndex = prayers.count
        focusedPrayer = nil

        // Fetch tomorrow's times
        Task {
            await fetchTomorrowPrayers()
        }
    }

    /// Create a unique key for a prayer (to track if played)
    private func makePrayerKey(_ prayer: Prayer) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: prayer.time)
        return "\(prayer.name)-\(dateStr)"
    }

    // MARK: - Day Rollover

    /// Check if we need to refresh for a new day
    private func checkDayRollover() {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)

        // At 00:01, refresh the data
        if hour == 0 && minute == 1 {
            let todayKey = makeTodayKey()
            let lastRefreshKey = UserDefaults.standard.string(forKey: "lastMidnightRefresh")

            if lastRefreshKey != todayKey {
                UserDefaults.standard.set(todayKey, forKey: "lastMidnightRefresh")
                performMidnightRefresh()
            }
        }
    }

    /// Schedule midnight refresh
    private func scheduleMidnightRefresh() {
        // The timer already runs every second and checkDayRollover handles this
    }

    /// Perform midnight refresh
    private func performMidnightRefresh() {
        print("PrayerTimesManager: Midnight refresh")

        // Reset state for new day
        playedPrayers.removeAll()
        currentPrayerIndex = 0
        hasFetchedTomorrow = false

        // Reload prayers
        Task {
            await loadPrayerTimes()
        }
    }

    private func makeTodayKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    // MARK: - Night Mode

    /// Update night mode based on current time and prayer schedule
    private func updateNightMode() {
        guard prayers.count >= 5 else {
            isNightMode = false
            return
        }

        let fajr = prayers[0].time
        let isha = prayers[4].time
        let now = currentTime

        // Night mode is active between Isha and Fajr
        // This is true if: now >= isha OR now < fajr
        let calendar = Calendar.current
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        let fajrComponents = calendar.dateComponents([.hour, .minute], from: fajr)
        let ishaComponents = calendar.dateComponents([.hour, .minute], from: isha)

        let nowMinutes = (nowComponents.hour ?? 0) * 60 + (nowComponents.minute ?? 0)
        let fajrMinutes = (fajrComponents.hour ?? 0) * 60 + (fajrComponents.minute ?? 0)
        let ishaMinutes = (ishaComponents.hour ?? 0) * 60 + (ishaComponents.minute ?? 0)

        isNightMode = nowMinutes >= ishaMinutes || nowMinutes < fajrMinutes
    }

    // MARK: - Manual Controls

    /// Manually refresh prayer times
    func refresh() async {
        await loadPrayerTimes()
    }

    /// Stop any playing adhan
    func stopAdhan() {
        audioManager.stopAdhan()
        isAdhanPlaying = false
    }

    // MARK: - Debug Controls

    /// Trigger adhan immediately (for testing)
    func triggerAdhanNow() {
        print("PrayerTimesManager: [DEBUG] Triggering adhan manually")
        isAdhanPlaying = true
        audioManager.playAdhan { [weak self] in
            Task { @MainActor in
                self?.isAdhanPlaying = false
            }
        }
    }

    /// Simulate the next prayer time being reached (for testing auto-play)
    func simulateNextPrayerTime() {
        guard let focused = focusedPrayer else {
            print("PrayerTimesManager: [DEBUG] No focused prayer to simulate")
            return
        }

        print("PrayerTimesManager: [DEBUG] Simulating \(focused.name) prayer time reached")

        // Mark as played and trigger adhan (advance happens when adhan finishes)
        let prayerKey = makePrayerKey(focused)
        if !playedPrayers.contains(prayerKey) {
            playedPrayers.insert(prayerKey)
            playAdhan(for: focused)
        } else {
            print("PrayerTimesManager: [DEBUG] Prayer already played, just triggering adhan")
            isAdhanPlaying = true
            audioManager.playAdhan { [weak self] in
                Task { @MainActor in
                    self?.isAdhanPlaying = false
                }
            }
        }
    }
}
