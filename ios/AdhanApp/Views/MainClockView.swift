import SwiftUI

/// Large clock display showing current time
/// Full styling in Phase 5
struct MainClockView: View {
    let currentTime: Date

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: currentTime)
    }

    var body: some View {
        Text(timeString)
            .font(.system(size: 120, weight: .thin, design: .default))
            .foregroundColor(.white)
            .monospacedDigit()
    }
}

#Preview {
    ZStack {
        Color.black
        MainClockView(currentTime: Date())
    }
}
