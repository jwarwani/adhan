import Foundation
import AVFoundation

/// Manages adhan audio playback with proper AVAudioSession configuration.
/// Configured for reliable playback even when screen is locked.
class AdhanAudioManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = AdhanAudioManager()

    private var audioPlayer: AVAudioPlayer?
    @Published var isPlaying = false

    private override init() {
        super.init()
        configureAudioSession()
        observeInterruptions()
    }

    // MARK: - Audio Session Configuration

    /// Configure AVAudioSession for reliable background/locked-screen playback
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()

            // .playback category:
            // - Audio plays even when silent switch is on
            // - Audio continues when screen is locked
            // - Audio continues when app is backgrounded
            try session.setCategory(.playback, mode: .default, options: [])

            // Activate the session
            try session.setActive(true)

            print("AdhanAudioManager: Audio session configured successfully")
        } catch {
            print("AdhanAudioManager: Failed to configure audio session - \(error)")
        }
    }

    /// Observe audio interruptions (phone calls, Siri, other apps)
    private func observeInterruptions() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            // Interruption began (e.g., phone call started)
            print("AdhanAudioManager: Audio interrupted")
            // Audio will pause automatically

        case .ended:
            // Interruption ended
            print("AdhanAudioManager: Audio interruption ended")
            // Check if we should resume
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    // Resume playback
                    audioPlayer?.play()
                }
            }

        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        switch reason {
        case .oldDeviceUnavailable:
            // Headphones unplugged - pause audio (standard iOS behavior)
            print("AdhanAudioManager: Audio route changed - old device unavailable")
        case .newDeviceAvailable:
            // New device connected (headphones, bluetooth)
            print("AdhanAudioManager: Audio route changed - new device available")
        default:
            break
        }
    }

    // MARK: - Playback Control

    /// Play the adhan audio file
    func playAdhan() {
        // Find the audio file in the bundle
        guard let url = Bundle.main.url(forResource: "adhan", withExtension: "mp3") else {
            print("AdhanAudioManager: ERROR - adhan.mp3 not found in bundle")
            return
        }

        do {
            // Ensure audio session is active
            try AVAudioSession.sharedInstance().setActive(true)

            // Create and configure the audio player
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()

            // Start playback
            let success = audioPlayer?.play() ?? false

            if success {
                isPlaying = true
                print("AdhanAudioManager: Adhan playback started")
            } else {
                print("AdhanAudioManager: ERROR - playback failed to start")
            }
        } catch {
            print("AdhanAudioManager: ERROR - \(error)")
        }
    }

    /// Stop the adhan audio
    func stopAdhan() {
        audioPlayer?.stop()
        isPlaying = false
        print("AdhanAudioManager: Adhan playback stopped")
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        print("AdhanAudioManager: Adhan playback finished (success: \(flag))")
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        isPlaying = false
        print("AdhanAudioManager: Decode error - \(error?.localizedDescription ?? "unknown")")
    }
}
