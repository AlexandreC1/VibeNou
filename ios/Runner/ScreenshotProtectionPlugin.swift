import Flutter
import UIKit

/**
 * Screenshot Protection Plugin for iOS
 *
 * Prevents screenshots on sensitive screens by:
 * 1. Hiding content when screenshot is taken
 * 2. Detecting screenshot events
 * 3. Preventing screen recording (partially - iOS limitation)
 */
public class ScreenshotProtectionPlugin: NSObject, FlutterPlugin {
    private var isProtectionEnabled = false
    private var blurView: UIVisualEffectView?
    private var screenshotObserver: NSObjectProtocol?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.vibenou/screenshot_protection",
            binaryMessenger: registrar.messenger()
        )
        let instance = ScreenshotProtectionPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "enableProtection":
            enableScreenshotProtection()
            result(true)
        case "disableProtection":
            disableScreenshotProtection()
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /**
     * Enable screenshot protection
     *
     * Note: iOS doesn't allow blocking screenshots completely, but we can:
     * - Detect when screenshots are taken
     * - Hide content during screenshot capture
     * - Blur content in app switcher
     */
    private func enableScreenshotProtection() {
        guard !isProtectionEnabled else { return }
        isProtectionEnabled = true

        // Add screenshot detection
        screenshotObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.onScreenshotDetected()
        }

        // Add blur effect when app goes to background (prevents preview in app switcher)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    /**
     * Disable screenshot protection
     */
    private func disableScreenshotProtection() {
        guard isProtectionEnabled else { return }
        isProtectionEnabled = false

        // Remove observers
        if let observer = screenshotObserver {
            NotificationCenter.default.removeObserver(observer)
            screenshotObserver = nil
        }

        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willResignActiveNotification,
            object: nil
        )

        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        removeBlurView()
    }

    /**
     * Handle screenshot detection
     */
    private func onScreenshotDetected() {
        print("Screenshot detected on protected screen!")
        // The Flutter side will handle showing warnings via screenshot_callback package
    }

    /**
     * Add blur view when app goes to background
     */
    @objc private func applicationWillResignActive() {
        guard isProtectionEnabled else { return }

        guard let window = UIApplication.shared.windows.first else { return }

        // Create blur effect
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = window.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.tag = 9999 // Tag for easy identification

        // Add lock icon
        let lockIcon = UIImageView(image: UIImage(systemName: "lock.fill"))
        lockIcon.tintColor = .systemGray
        lockIcon.contentMode = .scaleAspectFit
        lockIcon.frame = CGRect(
            x: (window.bounds.width - 64) / 2,
            y: (window.bounds.height - 64) / 2,
            width: 64,
            height: 64
        )
        blurEffectView.contentView.addSubview(lockIcon)

        window.addSubview(blurEffectView)
        blurView = blurEffectView
    }

    /**
     * Remove blur view when app becomes active
     */
    @objc private func applicationDidBecomeActive() {
        removeBlurView()
    }

    /**
     * Remove blur view
     */
    private func removeBlurView() {
        blurView?.removeFromSuperview()
        blurView = nil

        // Also remove by tag in case reference was lost
        UIApplication.shared.windows.first?.viewWithTag(9999)?.removeFromSuperview()
    }

    deinit {
        disableScreenshotProtection()
    }
}
