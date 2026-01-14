import SwiftUI

/// Header showing Bismillah and date information
/// Scales proportionally based on screen width
struct DateHeaderView: View {
    let gregorianDate: String
    let hijriDate: String
    let screenWidth: CGFloat

    // Reference width: 10th gen iPad landscape (1180pt)
    private let referenceWidth: CGFloat = 1180

    private var scale: CGFloat {
        screenWidth / referenceWidth
    }

    var body: some View {
        VStack(spacing: 10 * scale) {
            // Bismillah
            Text("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
                .font(.system(size: 36 * scale))
                .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.13)) // Gold

            // Gregorian date
            Text(gregorianDate)
                .font(.system(size: 22 * scale))
                .foregroundColor(.white.opacity(0.8))

            // Hijri date
            Text(hijriDate)
                .font(.system(size: 20 * scale))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

#Preview {
    ZStack {
        Color.black
        DateHeaderView(
            gregorianDate: "Wednesday, January 8, 2025",
            hijriDate: "8 Rajab 1446",
            screenWidth: 1180
        )
    }
}
