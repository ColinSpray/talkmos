package com.talkmos.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

/// Kept alive only for as long as the screen is being shared. Android 14+
/// refuses to hand MediaProjection a capture session unless a foreground
/// service of type "mediaProjection" is already running when capture
/// begins — flutter_webrtc's own screen capturer never starts one, so this
/// exists purely to satisfy that requirement and has no other job. Started
/// and stopped from Dart via ScreenShareService (see MainActivity.kt's
/// SCREEN_SHARE_CHANNEL).
class ScreenShareForegroundService : Service() {
    companion object {
        private const val CHANNEL_ID = "talkmos_screen_share"
        private const val NOTIFICATION_ID = 8420

        /// Whether capture is allowed to begin. startForegroundService() only
        /// queues the start, so the caller has to wait for this rather than
        /// for that call to return.
        @Volatile
        var isForeground = false
            private set

        /// Run once, the moment the service reaches the foreground.
        @Volatile
        var onForeground: (() -> Unit)? = null
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "Screen sharing",
                    NotificationManager.IMPORTANCE_LOW
                ).apply { description = "Shown while you're sharing your screen on a call" }
            )
        }

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Sharing your screen")
            .setSmallIcon(android.R.drawable.ic_menu_share)
            .setOngoing(true)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        isForeground = true
        onForeground?.invoke()
        onForeground = null
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        isForeground = false
        onForeground = null
        super.onDestroy()
    }
}
