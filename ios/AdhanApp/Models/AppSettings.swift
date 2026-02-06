import Foundation
import SwiftUI

/// Central settings model for the Adhan app
/// Uses @AppStorage for automatic persistence to UserDefaults
class AppSettings: ObservableObject {

    // MARK: - Singleton

    static let shared = AppSettings()

    // MARK: - Prayer Calculation Settings

    /// Prayer time calculation method (AlAdhan API method parameter)
    @AppStorage("calculationMethod") var calculationMethod: Int = CalculationMethod.isna.rawValue

    /// Asr calculation school (AlAdhan API school parameter)
    @AppStorage("asrSchool") var asrSchool: Int = AsrSchool.hanafi.rawValue

    // MARK: - Location Settings

    /// Whether to use automatic GPS location
    @AppStorage("useAutoLocation") var useAutoLocation: Bool = true

    /// Manual location latitude (used when useAutoLocation is false)
    @AppStorage("manualLatitude") var manualLatitude: Double = 0

    /// Manual location longitude (used when useAutoLocation is false)
    @AppStorage("manualLongitude") var manualLongitude: Double = 0

    /// Manual location city name for display
    @AppStorage("manualCityName") var manualCityName: String = ""

    // MARK: - Per-Prayer Alert Modes

    /// Alert mode for Fajr prayer
    @AppStorage("alertModeFajr") var alertModeFajr: String = PrayerAlertMode.adhan.rawValue

    /// Alert mode for Dhuhr prayer
    @AppStorage("alertModeDhuhr") var alertModeDhuhr: String = PrayerAlertMode.adhan.rawValue

    /// Alert mode for Asr prayer
    @AppStorage("alertModeAsr") var alertModeAsr: String = PrayerAlertMode.adhan.rawValue

    /// Alert mode for Maghrib prayer
    @AppStorage("alertModeMaghrib") var alertModeMaghrib: String = PrayerAlertMode.adhan.rawValue

    /// Alert mode for Isha prayer
    @AppStorage("alertModeIsha") var alertModeIsha: String = PrayerAlertMode.adhan.rawValue

    // MARK: - Computed Properties

    /// Get the CalculationMethod enum value
    var calculationMethodEnum: CalculationMethod {
        CalculationMethod(rawValue: calculationMethod) ?? .isna
    }

    /// Get the AsrSchool enum value
    var asrSchoolEnum: AsrSchool {
        AsrSchool(rawValue: asrSchool) ?? .hanafi
    }

    // MARK: - Alert Mode Helpers

    /// Get the alert mode for a specific prayer
    /// - Parameter prayer: The prayer name (Fajr, Dhuhr, Asr, Maghrib, Isha)
    /// - Returns: The PrayerAlertMode for that prayer
    func alertMode(for prayer: String) -> PrayerAlertMode {
        let raw: String
        switch prayer {
        case "Fajr": raw = alertModeFajr
        case "Dhuhr": raw = alertModeDhuhr
        case "Asr": raw = alertModeAsr
        case "Maghrib": raw = alertModeMaghrib
        case "Isha": raw = alertModeIsha
        default: raw = PrayerAlertMode.adhan.rawValue
        }
        return PrayerAlertMode(rawValue: raw) ?? .adhan
    }

    /// Set the alert mode for a specific prayer
    /// - Parameters:
    ///   - mode: The PrayerAlertMode to set
    ///   - prayer: The prayer name (Fajr, Dhuhr, Asr, Maghrib, Isha)
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

    /// Check if adhan should play for a specific prayer
    /// - Parameter prayer: The prayer name
    /// - Returns: True if alert mode is .adhan
    func shouldPlayAdhan(for prayer: String) -> Bool {
        return alertMode(for: prayer) == .adhan
    }

    /// Check if notification should show for a specific prayer
    /// - Parameter prayer: The prayer name
    /// - Returns: True if alert mode is .adhan or .notification
    func shouldShowNotification(for prayer: String) -> Bool {
        let mode = alertMode(for: prayer)
        return mode == .adhan || mode == .notification
    }

    // MARK: - Location Helpers

    /// Get the effective location (manual or will need GPS)
    /// Returns nil if auto location is enabled (caller should use LocationService)
    var manualLocation: (latitude: Double, longitude: Double)? {
        guard !useAutoLocation else { return nil }
        guard manualLatitude != 0 || manualLongitude != 0 else { return nil }
        return (manualLatitude, manualLongitude)
    }

    /// Set manual location
    func setManualLocation(latitude: Double, longitude: Double, cityName: String) {
        manualLatitude = latitude
        manualLongitude = longitude
        manualCityName = cityName
        useAutoLocation = false
    }

    /// Clear manual location and revert to auto
    func clearManualLocation() {
        manualLatitude = 0
        manualLongitude = 0
        manualCityName = ""
        useAutoLocation = true
    }

    // MARK: - Reset

    /// Reset all settings to defaults
    func resetToDefaults() {
        calculationMethod = CalculationMethod.isna.rawValue
        asrSchool = AsrSchool.hanafi.rawValue
        useAutoLocation = true
        manualLatitude = 0
        manualLongitude = 0
        manualCityName = ""
        alertModeFajr = PrayerAlertMode.adhan.rawValue
        alertModeDhuhr = PrayerAlertMode.adhan.rawValue
        alertModeAsr = PrayerAlertMode.adhan.rawValue
        alertModeMaghrib = PrayerAlertMode.adhan.rawValue
        alertModeIsha = PrayerAlertMode.adhan.rawValue
    }
}
