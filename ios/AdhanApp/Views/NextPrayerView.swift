import SwiftUI

/// Shows "Next: Prayer @ Time" with countdown
/// Full styling in Phase 5
struct NextPrayerView: View {
    let prayer: Prayer?
    let currentTime: Date

    private var timeUntil: String {
        guard let prayer = prayer else { return "" }

        let interval = prayer.time.timeIntervalSince(currentTime)
        if interval <= 0 {
            return "Now"
        }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "in \(hours)h \(minutes)m"
        } else {
            return "in \(minutes)m"
        }
    }

    var body: some View {
        if let prayer = prayer {
            HStack(spacing: 12) {
                Text("Next:")
                    .foregroundColor(.white.opacity(0.6))

                Text(prayer.name)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.13))

                Text("@")
                    .foregroundColor(.white.opacity(0.6))

                Text(prayer.formattedTime)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Text(timeUntil)
                    .foregroundColor(.white.opacity(0.6))
            }
            .font(.system(size: 32))
        }
    }
}

#Preview {
    ZStack {
        Color.black
        NextPrayerView(
            prayer: Prayer.samples[1],
            currentTime: Date()
        )
    }
}
