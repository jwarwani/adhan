import Foundation

/// Defines how the app should alert the user when a prayer time arrives
enum PrayerAlertMode: String, CaseIterable, Codable {
    case adhan = "adhan"              // Full adhan audio plays
    case notification = "notification" // Visual indicator only, no sound
    case silent = "silent"            // No alert at all

    /// Display name for settings UI
    var displayName: String {
        switch self {
        case .adhan: return "Adhan"
        case .notification: return "Notification"
        case .silent: return "Silent"
        }
    }

    /// SF Symbol icon name for settings UI
    var icon: String {
        switch self {
        case .adhan: return "speaker.wave.3.fill"
        case .notification: return "bell.fill"
        case .silent: return "bell.slash.fill"
        }
    }

    /// Brief description for accessibility or tooltips
    var description: String {
        switch self {
        case .adhan: return "Play the full adhan audio"
        case .notification: return "Show visual notification only"
        case .silent: return "No alert"
        }
    }
}
