import Foundation

/// Represents a single prayer time
struct Prayer: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let arabicName: String
    let time: Date

    init(name: String, arabicName: String, time: Date) {
        self.id = "\(name)-\(time.timeIntervalSince1970)"
        self.name = name
        self.arabicName = arabicName
        self.time = time
    }

    /// Format time as HH:mm (24-hour)
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }
}

// MARK: - Sample Data for Previews

extension Prayer {
    static let samples: [Prayer] = [
        Prayer(name: "Fajr", arabicName: "الفجر", time: Calendar.current.date(bySettingHour: 5, minute: 30, second: 0, of: Date())!),
        Prayer(name: "Dhuhr", arabicName: "الظهر", time: Calendar.current.date(bySettingHour: 12, minute: 30, second: 0, of: Date())!),
        Prayer(name: "Asr", arabicName: "العصر", time: Calendar.current.date(bySettingHour: 15, minute: 45, second: 0, of: Date())!),
        Prayer(name: "Maghrib", arabicName: "المغرب", time: Calendar.current.date(bySettingHour: 18, minute: 15, second: 0, of: Date())!),
        Prayer(name: "Isha", arabicName: "العشاء", time: Calendar.current.date(bySettingHour: 19, minute: 45, second: 0, of: Date())!)
    ]
}
