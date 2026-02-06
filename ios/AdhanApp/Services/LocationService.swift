import Foundation
import CoreLocation

/// Manages location services for prayer time calculation
class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()

    // MARK: - Fallback Location (Queens, NY)
    static let fallbackLatitude = 40.7282
    static let fallbackLongitude = -73.7949
    static let fallbackCity = "Queens, NY"

    // MARK: - Published State
    @Published var latitude: Double = fallbackLatitude
    @Published var longitude: Double = fallbackLongitude
    @Published var cityName: String = fallbackCity
    @Published var isAuthorized = false
    @Published var isLoading = false

    // MARK: - Private
    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    // Settings reference
    private var settings: AppSettings { AppSettings.shared }

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer // Don't need high precision
        loadCachedCityName()
    }

    // MARK: - Public API

    /// Request location permission and get current location
    /// Falls back to Queens, NY if permission denied or error occurs
    /// Respects manual location setting from AppSettings
    func requestLocation() async {
        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { self.isLoading = false } } }

        // Check if user has set a manual location
        if !settings.useAutoLocation, let manual = settings.manualLocation {
            await MainActor.run {
                self.latitude = manual.latitude
                self.longitude = manual.longitude
                self.cityName = settings.manualCityName.isEmpty ? "Manual Location" : settings.manualCityName
            }
            AppLogger.shared.info("Using manual location: \(cityName) (\(String(format: "%.4f", manual.latitude)), \(String(format: "%.4f", manual.longitude)))", category: "location")
            return
        }

        // Check current authorization status
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            // Request permission
            AppLogger.shared.info("Requesting location permission", category: "location")
            locationManager.requestWhenInUseAuthorization()
            // Wait a moment for the user to respond
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            // Check status again
            let newStatus = locationManager.authorizationStatus
            if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                await getLocationAndGeocode()
            } else {
                await useFallbackOrCached()
            }

        case .authorizedWhenInUse, .authorizedAlways:
            await MainActor.run { isAuthorized = true }
            await getLocationAndGeocode()

        case .denied, .restricted:
            AppLogger.shared.info("Location permission denied, using fallback", category: "location")
            await MainActor.run { isAuthorized = false }
            await useFallbackOrCached()

        @unknown default:
            await useFallbackOrCached()
        }
    }

    private func getLocationAndGeocode() async {
        do {
            let location = try await getCurrentLocation()
            await MainActor.run {
                self.latitude = location.coordinate.latitude
                self.longitude = location.coordinate.longitude
            }
            AppLogger.shared.info("Got GPS location: (\(String(format: "%.4f", latitude)), \(String(format: "%.4f", longitude)))", category: "location")

            // Reverse geocode for city name
            await reverseGeocode(latitude: latitude, longitude: longitude)

            // Cache the location
            cacheLocation()
        } catch {
            AppLogger.shared.error("Error getting location: \(error.localizedDescription)", category: "location")
            await useFallbackOrCached()
        }
    }

    /// Get current location with timeout
    private func getCurrentLocation() async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            locationManager.requestLocation()

            // Timeout after 10 seconds
            Task {
                try? await Task.sleep(nanoseconds: 10_000_000_000)
                if self.locationContinuation != nil {
                    self.locationContinuation?.resume(throwing: LocationError.timeout)
                    self.locationContinuation = nil
                }
            }
        }
    }

    /// Reverse geocode coordinates to get city name
    private func reverseGeocode(latitude: Double, longitude: Double) async {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: latitude, longitude: longitude)

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                let city = placemark.locality ?? placemark.administrativeArea ?? "Unknown"
                let country = placemark.isoCountryCode ?? ""

                await MainActor.run {
                    self.cityName = country.isEmpty ? city : "\(city), \(country)"
                }
                AppLogger.shared.info("Reverse geocoded to: \(cityName)", category: "location")
            }
        } catch {
            AppLogger.shared.error("Reverse geocode failed: \(error.localizedDescription)", category: "location")
            // Keep previous city name or use coordinates
            await MainActor.run {
                self.cityName = String(format: "%.2f, %.2f", latitude, longitude)
            }
        }
    }

    /// Use fallback location or cached location
    private func useFallbackOrCached() async {
        // Try cached location first
        if let cached = AlAdhanService.shared.getCachedLocation() {
            await MainActor.run {
                self.latitude = cached.latitude
                self.longitude = cached.longitude
            }
            AppLogger.shared.info("Using cached location", category: "location")
        } else {
            // Use fallback
            await MainActor.run {
                self.latitude = Self.fallbackLatitude
                self.longitude = Self.fallbackLongitude
                self.cityName = Self.fallbackCity
            }
            AppLogger.shared.info("Using fallback location (Queens, NY)", category: "location")
        }
    }

    /// Cache current location
    private func cacheLocation() {
        UserDefaults.standard.set(latitude, forKey: "cachedLatitude")
        UserDefaults.standard.set(longitude, forKey: "cachedLongitude")
        UserDefaults.standard.set(cityName, forKey: "cachedCityName")
    }

    /// Load cached city name
    private func loadCachedCityName() {
        if let cached = UserDefaults.standard.string(forKey: "cachedCityName") {
            cityName = cached
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        locationContinuation?.resume(returning: location)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        AppLogger.shared.error("Location manager error: \(error.localizedDescription)", category: "location")
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        DispatchQueue.main.async {
            self.isAuthorized = (status == .authorizedWhenInUse || status == .authorizedAlways)
        }
        AppLogger.shared.info("Location authorization changed to: \(status.rawValue)", category: "location")
    }
}

// MARK: - Errors

enum LocationError: LocalizedError {
    case timeout
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .timeout:
            return "Location request timed out"
        case .permissionDenied:
            return "Location permission denied"
        }
    }
}
