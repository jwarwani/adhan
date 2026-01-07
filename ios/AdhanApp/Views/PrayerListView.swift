import SwiftUI

/// Grid of 5 prayer time cards
/// Full styling in Phase 5
struct PrayerListView: View {
    let prayers: [Prayer]
    let nextPrayer: Prayer?

    var body: some View {
        HStack(spacing: 20) {
            ForEach(prayers) { prayer in
                PrayerCard(
                    prayer: prayer,
                    isNext: prayer.id == nextPrayer?.id
                )
            }
        }
    }
}

struct PrayerCard: View {
    let prayer: Prayer
    let isNext: Bool

    var body: some View {
        VStack(spacing: 8) {
            // Arabic name
            Text(prayer.arabicName)
                .font(.system(size: 24))
                .foregroundColor(isNext ? Color(red: 0.85, green: 0.65, blue: 0.13) : .white)

            // English name
            Text(prayer.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isNext ? Color(red: 0.85, green: 0.65, blue: 0.13) : .white.opacity(0.8))

            // Time
            Text(prayer.formattedTime)
                .font(.system(size: 28, weight: .light))
                .monospacedDigit()
                .foregroundColor(isNext ? Color(red: 0.85, green: 0.65, blue: 0.13) : .white)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isNext ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isNext ? Color(red: 0.85, green: 0.65, blue: 0.13) : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    ZStack {
        Color.black
        PrayerListView(
            prayers: Prayer.samples,
            nextPrayer: Prayer.samples[1]
        )
        .padding()
    }
}
