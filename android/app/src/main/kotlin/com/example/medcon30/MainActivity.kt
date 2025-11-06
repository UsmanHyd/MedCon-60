package com.example.medcon30

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.medcon30/permissions"
    private val NOTIFICATION_CHANNEL_ID = "sos_call_notification"
    private val NOTIFICATION_ID = 999

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = android.app.NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "SOS Emergency Calls",
                android.app.NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for SOS emergency calls - opens dialer automatically"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 200, 500, 200, 500)
            }
            val notificationManager = getSystemService(android.content.Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        val permissionsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        permissionsChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestForegroundServicePhoneCallPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) { // Android 14 (API 34)
                        val permission = Manifest.permission.FOREGROUND_SERVICE_PHONE_CALL
                        if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
                            ActivityCompat.requestPermissions(this, arrayOf(permission), 1001)
                            result.success(true)
                        } else {
                            result.success(true)
                        }
                    } else {
                        result.success(true) // Permission not needed on older Android versions
                    }
                }
                "showCallNotification" -> {
                    val phone = call.argument<String>("phone") ?: ""
                    val contactName = call.argument<String>("contactName") ?: "Contact"
                    showCallNotification(phone, contactName)
                    result.success(true)
                }
                "openDialer" -> {
                    val phone = call.argument<String>("phone") ?: ""
                    openDialer(phone)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun showCallNotification(phone: String, contactName: String) {
        // Create intent that opens the dialer DIRECTLY (works even from WhatsApp)
        val dialIntent = Intent(Intent.ACTION_DIAL).apply {
            data = Uri.parse("tel:$phone")
            // These flags ensure it works even when app is in background
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TASK
            // Add category to help system identify this as a call action
            addCategory(Intent.CATEGORY_DEFAULT)
        }
        
        // Use FLAG_IMMUTABLE for Android 12+ and FLAG_UPDATE_CURRENT to update if exists
        val pendingIntent = android.app.PendingIntent.getActivity(
            this,
            phone.hashCode(), // Use phone number as request code for uniqueness
            dialIntent,
            android.app.PendingIntent.FLAG_UPDATE_CURRENT or
            android.app.PendingIntent.FLAG_IMMUTABLE
        )

        // Create high-priority notification with full-screen intent
        // This will AUTOMATICALLY open the dialer even when user is in WhatsApp!
        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.sym_action_call) // Use call icon
            .setContentTitle("🚨 MedCon SOS - Emergency Call")
            .setContentText("Opening dialer to call $contactName...")
            .setPriority(NotificationCompat.PRIORITY_MAX) // Maximum priority
            .setDefaults(NotificationCompat.DEFAULT_ALL) // Sound, vibration, lights
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setAutoCancel(true) // Dismiss when tapped
            .setContentIntent(pendingIntent) // Main tap action
            .setFullScreenIntent(pendingIntent, true) // AUTO-OPENS dialer even from WhatsApp!
            .setVibrate(longArrayOf(0, 500, 200, 500, 200, 500)) // Very strong vibration
            .setSound(android.provider.Settings.System.DEFAULT_NOTIFICATION_URI)
            .setLights(android.graphics.Color.RED, 1000, 1000) // Red LED blinking
            .setStyle(NotificationCompat.BigTextStyle()
                .bigText("🚨 EMERGENCY CALL REQUIRED\n\nContact: $contactName\nPhone: $phone\n\nOpening dialer now..."))
            .setTimeoutAfter(30000) // Auto-dismiss after 30 seconds
            .build()

        val notificationManager = NotificationManagerCompat.from(this)
        if (ActivityCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            // Use a unique ID based on phone number so each notification replaces the previous
            notificationManager.notify(phone.hashCode(), notification)
            println("📱 Notification shown for $contactName ($phone)")
        } else {
            println("⚠️ POST_NOTIFICATIONS permission not granted")
        }
    }

    private fun openDialer(phone: String) {
        val dialIntent = Intent(Intent.ACTION_DIAL).apply {
            data = Uri.parse("tel:$phone")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(dialIntent)
    }
}
