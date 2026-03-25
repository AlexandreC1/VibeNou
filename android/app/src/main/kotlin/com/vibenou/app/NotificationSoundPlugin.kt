package com.vibenou.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Notification Sound Plugin for Android
 *
 * Manages custom notification sounds for VibeNou app
 */
class NotificationSoundPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var mediaPlayer: MediaPlayer? = null

    companion object {
        const val CHANNEL_ID = "vibenou_messages"
        const val CHANNEL_NAME = "Messages"
        const val CHANNEL_DESCRIPTION = "VibeNou message notifications"
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "com.vibenou/notification_sounds"
        )
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        mediaPlayer?.release()
        mediaPlayer = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "updateNotificationSound" -> {
                val soundName = call.argument<String>("soundName") ?: "purr"
                updateNotificationChannel(soundName)
                result.success(true)
            }
            "playSound" -> {
                val soundName = call.argument<String>("soundName") ?: "purr"
                playSound(soundName)
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * Update notification channel with custom sound
     */
    private fun updateNotificationChannel(soundName: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // Delete old channel if it exists
            notificationManager.deleteNotificationChannel(CHANNEL_ID)

            // Get sound URI
            val soundUri = getSoundUri(soundName)

            // Create audio attributes
            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .build()

            // Create new channel with custom sound
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = CHANNEL_DESCRIPTION
                enableLights(true)
                lightColor = android.graphics.Color.parseColor("#FF6B9D") // VibeNou pink
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 250, 250, 250) // Sexy vibration pattern
                setSound(soundUri, audioAttributes)
            }

            notificationManager.createNotificationChannel(channel)
        }
    }

    /**
     * Get URI for sound resource
     */
    private fun getSoundUri(soundName: String): Uri {
        val resourceId = context.resources.getIdentifier(
            soundName,
            "raw",
            context.packageName
        )

        return if (resourceId != 0) {
            // Custom sound exists
            Uri.parse("android.resource://${context.packageName}/$resourceId")
        } else {
            // Fallback to default notification sound
            RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        }
    }

    /**
     * Play sound preview
     */
    private fun playSound(soundName: String) {
        try {
            // Release previous player
            mediaPlayer?.release()

            val soundUri = getSoundUri(soundName)

            // Create and play new sound
            mediaPlayer = MediaPlayer().apply {
                setDataSource(context, soundUri)
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                        .build()
                )
                prepare()
                start()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
