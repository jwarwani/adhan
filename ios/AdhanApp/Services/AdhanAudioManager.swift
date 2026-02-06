import Foundation
import AVFoundation

/// Manages adhan audio playback with proper AVAudioSession configuration.
/// Configured for reliable playback even when screen is locked.
class AdhanAudioManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = AdhanAudioManager()

    private var audioPlayer: AVAudioPlayer?
    @Published var isPlaying = false
    private var completionHandler: (() -> Void)?

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

            AppLogger.shared.info("Audio session configured successfully", category: "audio")
        } catch {
            AppLogger.shared.error("Failed to configure audio session: \(error)", category: "audio")
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
            AppLogger.shared.info("Audio interrupted", category: "audio")
            // Audio will pause automatically

        case .ended:
            // Interruption ended
            AppLogger.shared.info("Audio interruption ended", category: "audio")
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
            AppLogger.shared.info("Audio route changed - old device unavailable", category: "audio")
        case .newDeviceAvailable:
            // New device connected (headphones, bluetooth)
            AppLogger.shared.info("Audio route changed - new device available", category: "audio")
        default:
            break
        }
    }

    // MARK: - Playback Control

    /// Play the adhan audio file (legacy method for backward compatibility)
    func playAdhan(completion: (() -> Void)? = nil) {
        playAdhan(for: nil, completion: completion)
    }

    /// Play the appropriate adhan for a prayer
    /// - Parameters:
    ///   - prayerName: Name of the prayer (used to select Fajr-specific audio). Pass nil for default.
    ///   - completion: Called when playback finishes
    func playAdhan(for prayerName: String?, completion: (() -> Void)? = nil) {
        // Store completion handler
        self.completionHandler = completion

        // Select appropriate audio file
        // Fajr uses a special adhan with "As-salatu khayrun min an-nawm"
        let isFajr = prayerName == "Fajr"
        let audioFileName = isFajr ? "adhan_fajr" : "adhan"

        // Try to find the audio file
        if let url = Bundle.main.url(forResource: audioFileName, withExtension: "mp3") {
            playAudioFile(url: url, prayerName: prayerName)
        } else if isFajr, let fallbackURL = Bundle.main.url(forResource: "adhan", withExtension: "mp3") {
            // Fajr-specific audio not found, fallback to standard adhan
            AppLogger.shared.info("Fajr adhan not found, using standard adhan", category: "audio")
            playAudioFile(url: fallbackURL, prayerName: prayerName)
        } else {
            AppLogger.shared.fault("Adhan audio file not found: \(audioFileName).mp3", category: "audio")
            completion?()
        }
    }

    /// Play an audio file from URL
    private func playAudioFile(url: URL, prayerName: String?) {
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
                let prayerInfo = prayerName.map { " for \($0)" } ?? ""
                AppLogger.shared.info("Adhan playback started\(prayerInfo): \(url.lastPathComponent)", category: "audio")
            } else {
                AppLogger.shared.error("Adhan playback failed to start", category: "audio")
                completionHandler?()
            }
        } catch {
            AppLogger.shared.error("Audio player error: \(error)", category: "audio")
            completionHandler?()
        }
    }

    /// Stop the adhan audio
    func stopAdhan() {
        audioPlayer?.stop()
        isPlaying = false
        AppLogger.shared.info("Adhan playback stopped", category: "audio")
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        AppLogger.shared.info("Adhan playback finished (success: \(flag))", category: "audio")
        completionHandler?()
        completionHandler = nil
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        isPlaying = false
        AppLogger.shared.error("Audio decode error: \(error?.localizedDescription ?? "unknown")", category: "audio")
        completionHandler?()
        completionHandler = nil
    }
}
