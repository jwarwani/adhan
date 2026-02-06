import UIKit

extension UIDevice {

    /// Device model identifier (e.g., "iPhone14,2")
    var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    /// Human-readable device model name (e.g., "iPhone 13 Pro")
    var modelName: String {
        let identifier = modelIdentifier

        // Simulator
        if identifier == "x86_64" || identifier == "arm64" {
            return "Simulator (\(ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "Unknown"))"
        }

        // iPhone models
        let iPhoneModels: [String: String] = [
            "iPhone14,2": "iPhone 13 Pro",
            "iPhone14,3": "iPhone 13 Pro Max",
            "iPhone14,4": "iPhone 13 mini",
            "iPhone14,5": "iPhone 13",
            "iPhone14,6": "iPhone SE (3rd gen)",
            "iPhone14,7": "iPhone 14",
            "iPhone14,8": "iPhone 14 Plus",
            "iPhone15,2": "iPhone 14 Pro",
            "iPhone15,3": "iPhone 14 Pro Max",
            "iPhone15,4": "iPhone 15",
            "iPhone15,5": "iPhone 15 Plus",
            "iPhone16,1": "iPhone 15 Pro",
            "iPhone16,2": "iPhone 15 Pro Max",
            "iPhone17,1": "iPhone 16 Pro",
            "iPhone17,2": "iPhone 16 Pro Max",
            "iPhone17,3": "iPhone 16",
            "iPhone17,4": "iPhone 16 Plus",
        ]

        // iPad models
        let iPadModels: [String: String] = [
            "iPad13,4": "iPad Pro 11-inch (3rd gen)",
            "iPad13,5": "iPad Pro 11-inch (3rd gen)",
            "iPad13,6": "iPad Pro 11-inch (3rd gen)",
            "iPad13,7": "iPad Pro 11-inch (3rd gen)",
            "iPad13,8": "iPad Pro 12.9-inch (5th gen)",
            "iPad13,9": "iPad Pro 12.9-inch (5th gen)",
            "iPad13,10": "iPad Pro 12.9-inch (5th gen)",
            "iPad13,11": "iPad Pro 12.9-inch (5th gen)",
            "iPad13,16": "iPad Air (5th gen)",
            "iPad13,17": "iPad Air (5th gen)",
            "iPad13,18": "iPad (10th gen)",
            "iPad13,19": "iPad (10th gen)",
            "iPad14,3": "iPad Pro 11-inch (4th gen)",
            "iPad14,4": "iPad Pro 11-inch (4th gen)",
            "iPad14,5": "iPad Pro 12.9-inch (6th gen)",
            "iPad14,6": "iPad Pro 12.9-inch (6th gen)",
            "iPad14,8": "iPad Air (6th gen)",
            "iPad14,9": "iPad Air (6th gen)",
            "iPad14,10": "iPad Air 13-inch (6th gen)",
            "iPad14,11": "iPad Air 13-inch (6th gen)",
            "iPad16,3": "iPad Pro 11-inch (5th gen)",
            "iPad16,4": "iPad Pro 11-inch (5th gen)",
            "iPad16,5": "iPad Pro 13-inch (5th gen)",
            "iPad16,6": "iPad Pro 13-inch (5th gen)",
        ]

        // Check all model dictionaries
        if let name = iPhoneModels[identifier] {
            return name
        }
        if let name = iPadModels[identifier] {
            return name
        }

        // Return identifier if not found
        return identifier
    }

    /// Formatted device info for feedback/diagnostics
    var deviceInfoString: String {
        """
        Device: \(modelName)
        Identifier: \(modelIdentifier)
        iOS: \(systemVersion)
        """
    }

    /// Check if device is an iPad
    var isIPad: Bool {
        userInterfaceIdiom == .pad
    }

    /// Check if device is an iPhone
    var isIPhone: Bool {
        userInterfaceIdiom == .phone
    }
}
