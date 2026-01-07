import SwiftUI

struct ContentView: View {
    @StateObject private var audioManager = AdhanAudioManager.shared

    var body: some View {
        ZStack {
            // Background color
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text("Adhan App")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.white)

                Text("Phase 2: Audio Validation")
                    .font(.system(size: 24))
                    .foregroundColor(.gray)

                // Audio test section
                VStack(spacing: 20) {
                    Text("CRITICAL TEST")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.orange)

                    Text("1. Tap 'Play Adhan' below\n2. While audio is playing, LOCK THE SCREEN\n3. If audio continues, Phase 2 passes!")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    HStack(spacing: 20) {
                        Button(action: {
                            audioManager.playAdhan()
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Play Adhan")
                            }
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.black)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(Color.green)
                            .cornerRadius(12)
                        }

                        Button(action: {
                            audioManager.stopAdhan()
                        }) {
                            HStack {
                                Image(systemName: "stop.fill")
                                Text("Stop")
                            }
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.black)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(Color.red)
                            .cornerRadius(12)
                        }
                    }

                    // Status indicator
                    HStack {
                        Circle()
                            .fill(audioManager.isPlaying ? Color.green : Color.gray)
                            .frame(width: 12, height: 12)
                        Text(audioManager.isPlaying ? "Audio Playing" : "Audio Stopped")
                            .foregroundColor(audioManager.isPlaying ? .green : .gray)
                    }
                    .font(.system(size: 16))
                }
                .padding(30)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                )

                // File check status
                VStack(spacing: 8) {
                    if Bundle.main.url(forResource: "adhan", withExtension: "mp3") != nil {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("adhan.mp3 found in bundle")
                                .foregroundColor(.green)
                        }
                    } else {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text("adhan.mp3 NOT FOUND - add to Xcode project")
                                .foregroundColor(.red)
                        }
                    }
                }
                .font(.system(size: 14))
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
