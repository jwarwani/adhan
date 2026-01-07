import Foundation

/// Service for fetching prayer times from AlAdhan API
/// Full implementation in Phase 1
class AlAdhanService {
    static let shared = AlAdhanService()

    private init() {}

    // MARK: - Placeholder for Phase 1

    /// Fetch prayer times for a location
    /// - Parameters:
    ///   - latitude: Location latitude
    ///   - longitude: Location longitude
    /// - Returns: Array of 5 Prayer objects
    func fetchPrayerTimes(latitude: Double, longitude: Double) async throws -> [Prayer] {
        // TODO: Implement in Phase 1
        // For now, return sample data
        return Prayer.samples
    }
}
