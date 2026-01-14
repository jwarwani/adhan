import SwiftUI

/// Dimming overlay for night mode (after Isha)
/// Full implementation in Phase 5
struct NightOverlayView: View {
    let isNightMode: Bool

    var body: some View {
        Rectangle()
            .fill(Color.black)
            .opacity(isNightMode ? 0.5 : 0)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .animation(.easeInOut(duration: 1.0), value: isNightMode)
    }
}

#Preview {
    ZStack {
        Color.blue
        NightOverlayView(isNightMode: true)
    }
}
