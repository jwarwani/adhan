import Foundation

extension Bundle {

    /// App version string (e.g., "1.0.0")
    var appVersionShort: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    }

    /// Build number (e.g., "42")
    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "?"
    }

    /// Combined version string (e.g., "1.0.0 (42)")
    var appVersion: String {
        "\(appVersionShort) (\(buildNumber))"
    }

    /// App display name
    var appDisplayName: String {
        infoDictionary?["CFBundleDisplayName"] as? String
            ?? infoDictionary?["CFBundleName"] as? String
            ?? "Adhan"
    }

    /// Bundle identifier
    var appBundleIdentifier: String {
        bundleIdentifier ?? "unknown"
    }

    /// Formatted version info for feedback/diagnostics
    var versionInfoString: String {
        """
        App: \(appDisplayName)
        Version: \(appVersion)
        Bundle ID: \(appBundleIdentifier)
        """
    }
}
