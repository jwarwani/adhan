import Foundation

/// Models for decoding AlAdhan API response
/// API Documentation: https://aladhan.com/prayer-times-api

struct AlAdhanResponse: Codable {
    let code: Int
    let status: String
    let data: AlAdhanData
}

struct AlAdhanData: Codable {
    let timings: AlAdhanTimings
    let date: AlAdhanDate
}

struct AlAdhanTimings: Codable {
    let Fajr: String
    let Sunrise: String
    let Dhuhr: String
    let Asr: String
    let Maghrib: String
    let Isha: String

    // We only use the 5 daily prayers, not Sunrise
}

struct AlAdhanDate: Codable {
    let readable: String
    let gregorian: AlAdhanGregorian
    let hijri: AlAdhanHijri
}

struct AlAdhanGregorian: Codable {
    let date: String
    let day: String
    let weekday: AlAdhanWeekday
    let month: AlAdhanMonth
    let year: String
}

struct AlAdhanHijri: Codable {
    let date: String
    let day: String
    let weekday: AlAdhanWeekday
    let month: AlAdhanMonth
    let year: String
}

struct AlAdhanWeekday: Codable {
    let en: String
    let ar: String?
}

struct AlAdhanMonth: Codable {
    let number: Int
    let en: String
    let ar: String?
}
