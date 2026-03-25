package com.vibenou.vibenou

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.vibenou.app.ScreenshotProtectionPlugin
import com.vibenou.app.NotificationSoundPlugin

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register plugins
        flutterEngine.plugins.add(ScreenshotProtectionPlugin())
        flutterEngine.plugins.add(NotificationSoundPlugin())
    }
}
