package com.vibenou.app

import android.app.Activity
import android.view.WindowManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Screenshot Protection Plugin for Android
 *
 * Prevents screenshots and screen recording on sensitive screens
 * by setting the FLAG_SECURE window flag.
 */
class ScreenshotProtectionPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "com.vibenou/screenshot_protection"
        )
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "enableProtection" -> {
                enableScreenshotProtection()
                result.success(true)
            }
            "disableProtection" -> {
                disableScreenshotProtection()
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * Enable screenshot protection by setting FLAG_SECURE
     *
     * This prevents:
     * - Screenshots
     * - Screen recording
     * - Screen content appearing in app switcher/recent apps
     */
    private fun enableScreenshotProtection() {
        activity?.runOnUiThread {
            activity?.window?.setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE
            )
        }
    }

    /**
     * Disable screenshot protection by clearing FLAG_SECURE
     */
    private fun disableScreenshotProtection() {
        activity?.runOnUiThread {
            activity?.window?.clearFlags(
                WindowManager.LayoutParams.FLAG_SECURE
            )
        }
    }

    // ActivityAware implementation
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
