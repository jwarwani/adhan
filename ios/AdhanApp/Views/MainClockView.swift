import SwiftUI

/// Large clock display showing current time
/// Scales proportionally based on screen width
struct MainClockView: View {
    let currentTime: Date
    let screenWidth: CGFloat

    // Reference width: 10th gen iPad landscape (1180pt)
    // All sizes are calibrated to look correct at this width
    private let referenceWidth: CGFloat = 1180

    private var scale: CGFloat {
        screenWidth / referenceWidth
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: currentTime)
    }

    var body: some View {
        Text(timeString)
            .font(.system(size: 180 * scale, weight: .thin, design: .default))
            .foregroundColor(.white)
            .monospacedDigit()
    }
}

#Preview {
    ZStack {
        Color.black
        MainClockView(currentTime: Date(), screenWidth: 1180)
    }
}
