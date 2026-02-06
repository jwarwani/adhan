import Foundation

/// Service for fetching prayer times from AlAdhan API
/// API Documentation: https://aladhan.com/prayer-times-api
class AlAdhanService {
    static let shared = AlAdhanService()

    // MARK: - Cache Keys
    private let cacheKey = "cachedPrayerTimes"
    private let cacheDateKey = "cachedPrayerDate"
    private let cacheLocationKey = "cachedLocation"

    // MARK: - Configuration
    private let baseURL = "https://api.aladhan.com/v1/timings"

    // Settings reference - uses AppSettings for calculation method and school
    private var settings: AppSettings { AppSettings.shared }

    private init() {}

    // MARK: - Public API

    /// Fetch prayer times for a location
    /// - Parameters:
    ///   - latitude: Location latitude
    ///   - longitude: Location longitude
    ///   - date: Date to fetch prayers for (defaults to today)
    /// - Returns: Array of 5 Prayer objects and date information
    func fetchPrayerTimes(
        latitude: Double,
        longitude: Double,
        date: Date = Date()
    ) async throws -> (prayers: [Prayer], gregorianDate: String, hijriDate: String) {
        // Try network first
        do {
            let result = try await fetchFromAPI(latitude: latitude, longitude: longitude, date: date)
            cache(result.prayers, location: (latitude, longitude))
            return result
        } catch {
            AppLogger.shared.error("Network error: \(error.localizedDescription)", category: "api")

            // Fall back to cache if network fails
            if let cached = getCachedPrayers(), isCacheValidForToday() {
                AppLogger.shared.info("Using cached prayer times", category: "api")
                return (cached, formatGregorianDate(date), "Cached")
            }

            throw error
        }
    }

    // MARK: - API Request

    private func fetchFromAPI(
        latitude: Double,
        longitude: Double,
        date: Date
    ) async throws -> (prayers: [Prayer], gregorianDate: String, hijriDate: String) {
        // Build URL with timestamp for the requested date
        let timestamp = Int(date.timeIntervalSince1970)
        let timezone = TimeZone.current.identifier

        // Get calculation settings from AppSettings
        let method = settings.calculationMethod
        let school = settings.asrSchool

        var components = URLComponents(string: "\(baseURL)/\(timestamp)")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "method", value: String(method)),
            URLQueryItem(name: "school", value: String(school)),
            URLQueryItem(name: "timezonestring", value: timezone)
        ]

        guard let url = components.url else {
            throw AlAdhanError.invalidURL
        }

        AppLogger.shared.info("Fetching prayers: method=\(settings.calculationMethodEnum.displayName), school=\(settings.asrSchoolEnum.displayName), lat=\(String(format: "%.4f", latitude)), lon=\(String(format: "%.4f", longitude))", category: "api")

        // Make request with retry logic
        let data = try await fetchWithRetry(url: url, maxRetries: 3)

        // Parse response
        let decoder = JSONDecoder()
        let response = try decoder.decode(AlAdhanResponse.self, from: data)

        guard response.code == 200 else {
            throw AlAdhanError.apiError(response.status)
        }

        // Convert timings to Prayer objects
        let prayers = try parsePrayers(from: response.data.timings, date: date)

        // Format dates
        let gregorianDate = formatGregorianDateFromAPI(response.data.date.gregorian)
        let hijriDate = formatHijriDateFromAPI(response.data.date.hijri)

        AppLogger.shared.info("Successfully fetched \(prayers.count) prayers", category: "api")
        return (prayers, gregorianDate, hijriDate)
    }

    private func fetchWithRetry(url: URL, maxRetries: Int) async throws -> Data {
        var lastError: Error = AlAdhanError.networkError

        for attempt in 0..<maxRetries {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw AlAdhanError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
                }

                return data
            } catch {
                lastError = error
                AppLogger.shared.error("API attempt \(attempt + 1) failed: \(error.localizedDescription)", category: "api")

                if attempt < maxRetries - 1 {
                    // Exponential backoff: 1s, 2s, 4s
                    let delay = UInt64(pow(2.0, Double(attempt))) * 1_000_000_000
                    try await Task.sleep(nanoseconds: delay)
                }
            }
        }

        throw lastError
    }

    // MARK: - Parsing

    private func parsePrayers(from timings: AlAdhanTimings, date: Date) throws -> [Prayer] {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)

        func parseTime(_ timeString: String, name: String, arabicName: String) throws -> Prayer {
            // Time format is "HH:mm" or "HH:mm (timezone)"
            let cleanTime = timeString.components(separatedBy: " ").first ?? timeString

            let parts = cleanTime.split(separator: ":")
            guard parts.count == 2,
                  let hour = Int(parts[0]),
                  let minute = Int(parts[1]) else {
                throw AlAdhanError.parseError("Invalid time format: \(timeString)")
            }

            var components = dateComponents
            components.hour = hour
            components.minute = minute
            components.second = 0

            guard let prayerDate = calendar.date(from: components) else {
                throw AlAdhanError.parseError("Could not create date for \(name)")
            }

            return Prayer(name: name, arabicName: arabicName, time: prayerDate)
        }

        return [
            try parseTime(timings.Fajr, name: "Fajr", arabicName: "الفجر"),
            try parseTime(timings.Dhuhr, name: "Dhuhr", arabicName: "الظهر"),
            try parseTime(timings.Asr, name: "Asr", arabicName: "العصر"),
            try parseTime(timings.Maghrib, name: "Maghrib", arabicName: "المغرب"),
            try parseTime(timings.Isha, name: "Isha", arabicName: "العشاء")
        ]
    }

    // MARK: - Date Formatting

    private func formatGregorianDateFromAPI(_ gregorian: AlAdhanGregorian) -> String {
        return "\(gregorian.weekday.en), \(gregorian.month.en) \(gregorian.day), \(gregorian.year)"
    }

    private func formatHijriDateFromAPI(_ hijri: AlAdhanHijri) -> String {
        return "\(hijri.day) \(hijri.month.en) \(hijri.year) AH"
    }

    private func formatGregorianDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }

    // MARK: - Caching

    private func cache(_ prayers: [Prayer], location: (lat: Double, lon: Double)) {
        if let data = try? JSONEncoder().encode(prayers) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date(), forKey: cacheDateKey)
            UserDefaults.standard.set([location.lat, location.lon], forKey: cacheLocationKey)
            AppLogger.shared.debug("Cached prayer times", category: "api")
        }
    }

    private func getCachedPrayers() -> [Prayer]? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let prayers = try? JSONDecoder().decode([Prayer].self, from: data) else {
            return nil
        }
        return prayers
    }

    private func isCacheValidForToday() -> Bool {
        guard let cacheDate = UserDefaults.standard.object(forKey: cacheDateKey) as? Date else {
            return false
        }
        return Calendar.current.isDateInToday(cacheDate)
    }

    /// Get cached location if available
    func getCachedLocation() -> (latitude: Double, longitude: Double)? {
        guard let coords = UserDefaults.standard.array(forKey: cacheLocationKey) as? [Double],
              coords.count == 2 else {
            return nil
        }
        return (coords[0], coords[1])
    }
}

// MARK: - Errors

enum AlAdhanError: LocalizedError {
    case invalidURL
    case networkError
    case httpError(Int)
    case apiError(String)
    case parseError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .networkError:
            return "Network connection failed"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let status):
            return "API error: \(status)"
        case .parseError(let message):
            return "Parse error: \(message)"
        }
    }
}
