import Flutter
import UIKit
import AVFoundation

/**
 * Notification Sound Plugin for iOS
 *
 * Manages custom notification sounds for VibeNou app
 */
public class NotificationSoundPlugin: NSObject, FlutterPlugin {
    private var audioPlayer: AVAudioPlayer?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.vibenou/notification_sounds",
            binaryMessenger: registrar.messenger()
        )
        let instance = NotificationSoundPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "updateNotificationSound":
            if let args = call.arguments as? [String: Any],
               let soundName = args["soundName"] as? String {
                updateNotificationSound(soundName: soundName)
                result(true)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            }

        case "playSound":
            if let args = call.arguments as? [String: Any],
               let soundName = args["soundName"] as? String {
                playSound(soundName: soundName)
                result(true)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /**
     * Update notification sound preference
     *
     * iOS requires sound files to be registered in the app bundle.
     * The actual sound is specified when sending the notification payload.
     */
    private func updateNotificationSound(soundName: String) {
        // Save preference to UserDefaults
        UserDefaults.standard.set(soundName, forKey: "notification_sound")
        UserDefaults.standard.synchronize()

        print("VibeNou: Notification sound updated to \(soundName)")
    }

    /**
     * Play sound preview
     */
    private func playSound(soundName: String) {
        guard let soundURL = getSoundURL(soundName: soundName) else {
            print("VibeNou: Sound file not found: \(soundName)")
            return
        }

        do {
            // Configure audio session
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            // Stop previous player
            audioPlayer?.stop()

            // Create and play new player
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.play()

            print("VibeNou: Playing sound preview: \(soundName)")
        } catch {
            print("VibeNou: Failed to play sound: \(error.localizedDescription)")
        }
    }

    /**
     * Get sound file URL from bundle
     */
    private func getSoundURL(soundName: String) -> URL? {
        // Look for sound file in bundle
        // Supports .caf, .aiff, .wav formats (iOS notification compatible)
        let formats = ["caf", "aiff", "wav", "m4a"]

        for format in formats {
            if let url = Bundle.main.url(forResource: soundName, withExtension: format) {
                return url
            }
        }

        // Fallback to default system sound
        return Bundle.main.url(forResource: "default", withExtension: "caf")
    }

    /**
     * Get current notification sound name
     */
    public static func getCurrentSound() -> String {
        return UserDefaults.standard.string(forKey: "notification_sound") ?? "purr"
    }

    /**
     * Get sound file name for notification payload
     *
     * Returns the sound file name with extension for iOS notification
     */
    public static func getSoundFileName(soundName: String) -> String {
        // iOS notifications require the file extension
        // We'll try to find the actual file in the bundle
        let formats = ["caf", "aiff", "wav", "m4a"]

        for format in formats {
            if Bundle.main.url(forResource: soundName, withExtension: format) != nil {
                return "\(soundName).\(format)"
            }
        }

        // Fallback to default
        return "default.caf"
    }
}
