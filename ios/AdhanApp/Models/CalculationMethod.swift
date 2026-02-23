import Foundation

/// Prayer time calculation methods supported by the AlAdhan API
/// Different regions and organizations use different astronomical calculations for Fajr and Isha times
enum CalculationMethod: Int, CaseIterable, Codable {
    case karachi = 1        // University of Islamic Sciences, Karachi
    case isna = 2           // Islamic Society of North America (default)
    case mwl = 3            // Muslim World League
    case ummAlQura = 4      // Umm Al-Qura University, Makkah
    case egyptian = 5       // Egyptian General Authority of Survey
    case tehran = 7         // Institute of Geophysics, University of Tehran

    /// Display name for settings UI
    var displayName: String {
        switch self {
        case .karachi: return "Karachi"
        case .isna: return "ISNA"
        case .mwl: return "Muslim World League"
        case .ummAlQura: return "Umm Al-Qura"
        case .egyptian: return "Egyptian"
        case .tehran: return "Tehran"
        }
    }

    /// Full descriptive name
    var fullName: String {
        switch self {
        case .karachi: return "University of Islamic Sciences, Karachi"
        case .isna: return "Islamic Society of North America"
        case .mwl: return "Muslim World League"
        case .ummAlQura: return "Umm Al-Qura University, Makkah"
        case .egyptian: return "Egyptian General Authority of Survey"
        case .tehran: return "Institute of Geophysics, Tehran"
        }
    }

    /// Regions where this method is commonly used
    var commonRegions: String {
        switch self {
        case .karachi: return "Pakistan, Bangladesh, India, Afghanistan, parts of Europe"
        case .isna: return "North America"
        case .mwl: return "Europe, Far East, parts of USA"
        case .ummAlQura: return "Saudi Arabia, Arabian Peninsula"
        case .egyptian: return "Africa, Syria, Iraq, Lebanon, Malaysia"
        case .tehran: return "Iran, Shia communities"
        }
    }

    /// Fajr angle used by this method
    var fajrAngle: Double {
        switch self {
        case .karachi: return 18.0
        case .isna: return 15.0
        case .mwl: return 18.0
        case .ummAlQura: return 18.5
        case .egyptian: return 19.5
        case .tehran: return 17.7
        }
    }

    /// Isha angle used by this method (0 means minutes after Maghrib)
    var ishaAngle: Double {
        switch self {
        case .karachi: return 18.0
        case .isna: return 15.0
        case .mwl: return 17.0
        case .ummAlQura: return 0  // 90 minutes after Maghrib
        case .egyptian: return 17.5
        case .tehran: return 14.0
        }
    }
}
