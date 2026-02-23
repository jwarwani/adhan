import Foundation
import os.log

/// Centralized logging for the Adhan app
/// Provides both system logging (os.log) and an in-memory buffer for feedback reports
class AppLogger {

    // MARK: - Singleton

    static let shared = AppLogger()

    // MARK: - Configuration

    private let subsystem = "com.adhan.app"
    private let maxBufferSize = 500

    // MARK: - Category Loggers

    /// General app events
    let general: Logger

    /// API/network related events
    let api: Logger

    /// Audio playback events
    let audio: Logger

    /// Location service events
    let location: Logger

    /// Settings changes
    let settings: Logger

    // MARK: - In-Memory Buffer

    /// Log entry for feedback reports
    struct LogEntry: Codable {
        let timestamp: Date
        let category: String
        let level: String
        let message: String

        var formattedString: String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return "[\(formatter.string(from: timestamp))] [\(category)] [\(level)] \(message)"
        }
    }

    private var logBuffer: [LogEntry] = []
    private let bufferQueue = DispatchQueue(label: "com.adhan.logger.buffer", attributes: .concurrent)

    // MARK: - Initialization

    private init() {
        general = Logger(subsystem: subsystem, category: "general")
        api = Logger(subsystem: subsystem, category: "api")
        audio = Logger(subsystem: subsystem, category: "audio")
        location = Logger(subsystem: subsystem, category: "location")
        settings = Logger(subsystem: subsystem, category: "settings")
    }

    // MARK: - Logging Methods

    /// Log a message with category and level
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: Category name (general, api, audio, location, settings)
    ///   - level: Log level (debug, info, error, fault)
    func log(_ message: String, category: String = "general", level: OSLogType = .info) {
        // Log to system
        let logger = Logger(subsystem: subsystem, category: category)
        switch level {
        case .debug:
            logger.debug("\(message, privacy: .public)")
        case .info:
            logger.info("\(message, privacy: .public)")
        case .error:
            logger.error("\(message, privacy: .public)")
        case .fault:
            logger.fault("\(message, privacy: .public)")
        default:
            logger.log("\(message, privacy: .public)")
        }

        // Store in buffer
        let entry = LogEntry(
            timestamp: Date(),
            category: category,
            level: levelString(level),
            message: message
        )

        bufferQueue.async(flags: .barrier) {
            self.logBuffer.append(entry)

            // Trim old entries if needed
            if self.logBuffer.count > self.maxBufferSize {
                self.logBuffer.removeFirst(self.logBuffer.count - self.maxBufferSize)
            }
        }
    }

    // MARK: - Convenience Methods

    /// Log a debug message
    func debug(_ message: String, category: String = "general") {
        log(message, category: category, level: .debug)
    }

    /// Log an info message
    func info(_ message: String, category: String = "general") {
        log(message, category: category, level: .info)
    }

    /// Log an error message
    func error(_ message: String, category: String = "general") {
        log(message, category: category, level: .error)
    }

    /// Log a fault message (critical error)
    func fault(_ message: String, category: String = "general") {
        log(message, category: category, level: .fault)
    }

    // MARK: - Buffer Access

    /// Get recent log entries
    /// - Parameter count: Maximum number of entries to return
    /// - Returns: Array of recent log entries
    func getRecentLogs(count: Int = 100) -> [LogEntry] {
        bufferQueue.sync {
            Array(logBuffer.suffix(count))
        }
    }

    /// Export logs as a formatted string for feedback
    /// - Parameter count: Maximum number of entries to include
    /// - Returns: Formatted log string
    func exportLogsAsString(count: Int = 100) -> String {
        let entries = getRecentLogs(count: count)
        return entries.map { $0.formattedString }.joined(separator: "\n")
    }

    /// Clear the log buffer
    func clearBuffer() {
        bufferQueue.async(flags: .barrier) {
            self.logBuffer.removeAll()
        }
    }

    /// Get buffer size
    var bufferCount: Int {
        bufferQueue.sync {
            logBuffer.count
        }
    }

    // MARK: - Private Helpers

    private func levelString(_ level: OSLogType) -> String {
        switch level {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .error: return "ERROR"
        case .fault: return "FAULT"
        default: return "DEFAULT"
        }
    }
}

// MARK: - Convenience Global Functions

/// Log a message to the app logger
/// - Parameters:
///   - message: The message to log
///   - category: Category name
///   - level: Log level
func appLog(_ message: String, category: String = "general", level: OSLogType = .info) {
    AppLogger.shared.log(message, category: category, level: level)
}
