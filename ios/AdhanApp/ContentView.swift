import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            // Background color
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Adhan App")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.white)

                Text("Phase 0: Project Foundation")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)

                Text("If you see this, the app builds and runs!")
                    .font(.system(size: 18))
                    .foregroundColor(.green)
            }
        }
        .onAppear {
            // Keep screen always on for kiosk mode
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
}

#Preview {
    ContentView()
}
