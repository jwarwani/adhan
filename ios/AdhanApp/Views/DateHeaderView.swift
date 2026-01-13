import SwiftUI

/// Header showing Bismillah and date information
/// Full styling in Phase 5
struct DateHeaderView: View {
    let gregorianDate: String
    let hijriDate: String

    var body: some View {
        VStack(spacing: 10) {
            // Bismillah
            Text("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
                .font(.system(size: 36))
                .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.13)) // Gold

            // Gregorian date
            Text(gregorianDate)
                .font(.system(size: 22))
                .foregroundColor(.white.opacity(0.8))

            // Hijri date
            Text(hijriDate)
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

#Preview {
    ZStack {
        Color.black
        DateHeaderView(
            gregorianDate: "Wednesday, January 8, 2025",
            hijriDate: "8 Rajab 1446"
        )
    }
}
