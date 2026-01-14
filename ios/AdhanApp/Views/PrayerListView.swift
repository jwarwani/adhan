import SwiftUI

/// Grid of 5 prayer time cards
/// Scales proportionally based on screen width
struct PrayerListView: View {
    let prayers: [Prayer]
    let focusedPrayer: Prayer?
    let isApproaching: Bool
    let isActive: Bool
    let screenWidth: CGFloat

    // Reference width: 10th gen iPad landscape (1180pt)
    private let referenceWidth: CGFloat = 1180

    private var scale: CGFloat {
        screenWidth / referenceWidth
    }

    var body: some View {
        HStack(spacing: 20 * scale) {
            ForEach(prayers) { prayer in
                PrayerCard(
                    prayer: prayer,
                    isNext: prayer.id == focusedPrayer?.id && !isApproaching && !isActive,
                    isApproaching: prayer.id == focusedPrayer?.id && isApproaching,
                    isActive: prayer.id == focusedPrayer?.id && isActive,
                    scale: scale
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
    var scale: CGFloat = 1.0

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
        VStack(spacing: 8 * scale) {
            // Active indicator
            if isActive {
                HStack(spacing: 4 * scale) {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 12 * scale))
                    Text("NOW")
                        .font(.system(size: 12 * scale, weight: .bold))
                }
                .foregroundColor(.green)
                .padding(.bottom, 4 * scale)
            } else if isApproaching {
                Text("SOON")
                    .font(.system(size: 12 * scale, weight: .bold))
                    .foregroundColor(.orange)
                    .padding(.bottom, 4 * scale)
            }

            // Arabic name
            Text(prayer.arabicName)
                .font(.system(size: 28 * scale))
                .foregroundColor(isNext || isApproaching || isActive ? cardColor : .white)

            // English name
            Text(prayer.name)
                .font(.system(size: 18 * scale, weight: .medium))
                .foregroundColor(isNext || isApproaching || isActive ? cardColor : .white.opacity(0.8))

            // Time
            Text(prayer.formattedTime)
                .font(.system(size: 32 * scale, weight: .light))
                .monospacedDigit()
                .foregroundColor(isNext || isApproaching || isActive ? cardColor : .white)
        }
        .padding(.vertical, 20 * scale)
        .padding(.horizontal, 28 * scale)
        .background(
            RoundedRectangle(cornerRadius: 12 * scale)
                .fill(isActive ? Color.green.opacity(0.2) : (isApproaching ? Color.orange.opacity(0.15) : (isNext ? Color.white.opacity(0.15) : Color.white.opacity(0.05))))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12 * scale)
                .stroke(isActive ? .green : (isApproaching ? .orange : (isNext ? goldColor : Color.clear)), lineWidth: (isActive ? 3 : 2) * scale)
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
            focusedPrayer: Prayer.samples[1],
            isApproaching: false,
            isActive: false,
            screenWidth: 1180
        )
        .padding()
    }
}
