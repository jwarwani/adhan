import SwiftUI

/// Grid of 5 prayer time cards
/// Full styling in Phase 5
struct PrayerListView: View {
    let prayers: [Prayer]
    let nextPrayer: Prayer?
    var approachingPrayer: Prayer? = nil
    var isAdhanPlaying: Bool = false

    var body: some View {
        HStack(spacing: 20) {
            ForEach(prayers) { prayer in
                PrayerCard(
                    prayer: prayer,
                    isNext: prayer.id == nextPrayer?.id,
                    isApproaching: prayer.id == approachingPrayer?.id,
                    isActive: isAdhanPlaying && prayer.id == nextPrayer?.id
                )
            }
        }
    }
}

struct PrayerCard: View {
    let prayer: Prayer
    let isNext: Bool
    var isApproaching: Bool = false
    var isActive: Bool = false

    // Gold accent color
    private let goldColor = Color(red: 0.85, green: 0.65, blue: 0.13)

    private var cardColor: Color {
        if isActive {
            return .green
        } else if isApproaching {
            return .orange
        } else if isNext {
            return goldColor
        } else {
            return .white
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Active indicator
            if isActive {
                HStack(spacing: 4) {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 12))
                    Text("NOW")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.green)
                .padding(.bottom, 4)
            } else if isApproaching {
                Text("SOON")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.orange)
                    .padding(.bottom, 4)
            }

            // Arabic name
            Text(prayer.arabicName)
                .font(.system(size: 28))
                .foregroundColor(isNext || isApproaching || isActive ? cardColor : .white)

            // English name
            Text(prayer.name)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isNext || isApproaching || isActive ? cardColor : .white.opacity(0.8))

            // Time
            Text(prayer.formattedTime)
                .font(.system(size: 32, weight: .light))
                .monospacedDigit()
                .foregroundColor(isNext || isApproaching || isActive ? cardColor : .white)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 28)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? Color.green.opacity(0.2) : (isApproaching ? Color.orange.opacity(0.15) : (isNext ? Color.white.opacity(0.15) : Color.white.opacity(0.05))))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? .green : (isApproaching ? .orange : (isNext ? goldColor : Color.clear)), lineWidth: isActive ? 3 : 2)
        )
        .animation(.easeInOut(duration: 0.3), value: isActive)
        .animation(.easeInOut(duration: 0.3), value: isApproaching)
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
