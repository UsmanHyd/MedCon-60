package com.example.medcon30

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.app.FlutterApplication

class MyApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        // Ensure notification channels exist before any foreground service starts
        createNotificationChannel(
            channelId = "sos_background_service",
            channelName = "SOS Background Service",
            importance = NotificationManager.IMPORTANCE_LOW
        )
        createNotificationChannel(
            channelId = "sos_call_notification",
            channelName = "SOS Emergency Calls",
            importance = NotificationManager.IMPORTANCE_HIGH
        )
    }

    private fun createNotificationChannel(channelId: String, channelName: String, importance: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(channelId, channelName, importance)
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }
}


