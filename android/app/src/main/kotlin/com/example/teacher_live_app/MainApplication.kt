package com.example.teacher_live_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import androidx.core.app.NotificationCompat
import io.flutter.app.FlutterApplication

class MainApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel(this)
    }

    companion object {
        const val CHANNEL_ID = "high_importance_channel"

        fun createNotificationChannel(context: Context) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                val audioAttributes = AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                    .build()

                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "High Importance Notifications",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Broadcasts, live class alerts, and announcements"
                    enableLights(true)
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 250, 150, 250)
                    setShowBadge(true)
                    setSound(soundUri, audioAttributes)
                    lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
                }

                val notificationManager = context.getSystemService(NotificationManager::class.java)
                notificationManager?.createNotificationChannel(channel)
            }
        }
    }
}
