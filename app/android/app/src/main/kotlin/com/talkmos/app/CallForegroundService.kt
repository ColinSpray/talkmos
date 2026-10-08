package com.talkmos.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

/// Runs for as long as a call does, so the call outlives the UI.
///
/// Swiping Talkmos out of recents destroys MainActivity; without a foreground
/// service nothing is left holding the process up, and the socket and media
/// session go with it. A started service (stopWithTask defaults to false)
/// keeps the process alive — the Flutter engine it is running survives too,
/// because MainActivity no longer owns it (see MainActivity.provideFlutterEngine).
///
/// Its notification deliberately shares the id and channel CallNotificationService
/// posts the ongoing-call notification on, so the shade shows one entry: this
/// service puts the call in the foreground, and Dart keeps that same
/// notification up to date with the peer's name and the Hang Up action.
class CallForegroundService : Service() {
    companion object {
        const val CHANNEL_ID = "talkmos_active_calls"
        const val NOTIFICATION_ID = 991101

        @Volatile
        var isRunning = false
            private set
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            getSystemService(NotificationManager::class.java).createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "Active Calls",
                    NotificationManager.IMPORTANCE_LOW
                ).apply { description = "Ongoing voice and video calls" }
            )
        }

        val open = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            ),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Ongoing call")
            .setContentText("Tap to return to the call")
            .setSmallIcon(R.drawable.ic_stat_talkmos)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setContentIntent(open)
            .build()

        // Microphone rather than phoneCall: the phoneCall type wants a
        // self-managed ConnectionService behind it, which this app does not
        // have, and Android 14 refuses the service outright without one.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        isRunning = true
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        isRunning = false
        super.onDestroy()
    }
}
