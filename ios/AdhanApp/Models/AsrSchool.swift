import Foundation

/// Juristic school for Asr prayer time calculation
/// The two methods can result in Asr times differing by 45-60 minutes
enum AsrSchool: Int, CaseIterable, Codable {
    case standard = 0   // Shafi'i, Maliki, Hanbali (shadow = 1x object height)
    case hanafi = 1     // Hanafi (shadow = 2x object height)

    /// Display name for settings UI
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .hanafi: return "Hanafi"
        }
    }

    /// Full descriptive name with schools
    var fullName: String {
        switch self {
        case .standard: return "Standard (Shafi'i, Maliki, Hanbali)"
        case .hanafi: return "Hanafi"
        }
    }

    /// Brief explanation for settings
    var description: String {
        switch self {
        case .standard: return "Shadow equals object height"
        case .hanafi: return "Shadow equals twice object height"
        }
    }

    /// Regions where this school is commonly followed
    var commonRegions: String {
        switch self {
        case .standard: return "Most of the Muslim world"
        case .hanafi: return "South Asia, Turkey, Central Asia"
        }
    }

    /// Shadow factor multiplier (1 or 2)
    var shadowFactor: Int {
        switch self {
        case .standard: return 1
        case .hanafi: return 2
        }
    }
}
