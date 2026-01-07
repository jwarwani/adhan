import SwiftUI

/// First-run instructions for setting up Guided Access kiosk mode
/// Full implementation in Phase 6
struct KioskInstructionsView: View {
    @Binding var isPresented: Bool
    @AppStorage("hasSeenKioskInstructions") private var hasSeenInstructions = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Text("Welcome to Adhan Prayer Clock")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 16) {
                    Text("For the best experience, set up Kiosk Mode:")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.9))

                    VStack(alignment: .leading, spacing: 12) {
                        InstructionRow(number: 1, text: "Go to Settings → Accessibility → Guided Access")
                        InstructionRow(number: 2, text: "Turn on Guided Access")
                        InstructionRow(number: 3, text: "Set a passcode")
                        InstructionRow(number: 4, text: "Return to this app")
                        InstructionRow(number: 5, text: "Triple-click the side button")
                        InstructionRow(number: 6, text: "Tap \"Start\" in the top right")
                    }

                    Text("This keeps the prayer clock always visible and prevents accidental exits.")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 8)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                )

                Button(action: {
                    hasSeenInstructions = true
                    isPresented = false
                }) {
                    Text("Got it, don't show again")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(Color(red: 0.85, green: 0.65, blue: 0.13))
                        .cornerRadius(12)
                }
            }
            .padding(48)
        }
    }
}

struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number).")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(red: 0.85, green: 0.65, blue: 0.13))
                .frame(width: 24)

            Text(text)
                .font(.system(size: 18))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    KioskInstructionsView(isPresented: .constant(true))
}
