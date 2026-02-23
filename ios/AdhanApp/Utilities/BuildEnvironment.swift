import Foundation

/// Utility for detecting the build environment
/// Used to conditionally enable debug features
enum BuildEnvironment {

    // MARK: - Environment Detection

    /// Check if running in Xcode debug build
    static var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    /// Check if running from TestFlight
    /// TestFlight builds have a sandbox receipt
    static var isTestFlight: Bool {
        guard let receiptURL = Bundle.main.appStoreReceiptURL else {
            return false
        }
        return receiptURL.lastPathComponent == "sandboxReceipt"
    }

    /// Check if running from the App Store
    static var isAppStore: Bool {
        guard let receiptURL = Bundle.main.appStoreReceiptURL else {
            return false
        }
        // App Store receipts are not in sandbox
        return receiptURL.lastPathComponent != "sandboxReceipt" && !isDebugBuild
    }

    /// Check if running in simulator
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    // MARK: - Feature Flags

    /// Whether debug features should be allowed
    /// - DEBUG builds: Always allowed
    /// - TestFlight: Allowed (for beta testing)
    /// - App Store: Never allowed
    static var allowDebugFeatures: Bool {
        #if DEBUG
        return true
        #else
        return isTestFlight
        #endif
    }

    /// Whether verbose logging should be enabled
    static var verboseLoggingEnabled: Bool {
        #if DEBUG
        return true
        #else
        return isTestFlight
        #endif
    }

    /// Whether to show diagnostic info in error messages
    static var showDiagnosticInfo: Bool {
        // Show in debug and TestFlight, not in App Store
        return allowDebugFeatures
    }

    // MARK: - Build Info

    /// Current build configuration name
    static var configurationName: String {
        if isDebugBuild {
            return "Debug"
        } else if isTestFlight {
            return "TestFlight"
        } else if isAppStore {
            return "App Store"
        } else {
            return "Release"
        }
    }

    /// Description of current environment
    static var environmentDescription: String {
        var components: [String] = []

        components.append(configurationName)

        if isSimulator {
            components.append("Simulator")
        }

        return components.joined(separator: " - ")
    }
}
