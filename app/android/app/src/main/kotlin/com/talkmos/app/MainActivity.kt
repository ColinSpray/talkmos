package com.talkmos.app

import android.app.NotificationManager
import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.res.Configuration
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.util.Rational
import android.view.WindowManager
import org.json.JSONObject
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "TalkmosMain"

        // Set by flutter_local_notifications on the intent it launches this
        // activity with, for both a notification tap and a full-screen intent
        // (its `SELECT_NOTIFICATION` / `PAYLOAD`). Mirrored here because they
        // are private to the plugin.
        private const val SELECT_NOTIFICATION = "SELECT_NOTIFICATION"
        private const val NOTIFICATION_PAYLOAD_EXTRA = "payload"

        private const val CALL_ACTIVITY_CHANNEL = "com.talkmos.app/call_activity"
        private const val CALL_EVENTS_CHANNEL = "com.talkmos.app/call_events"
        private const val RINGTONE_CHANNEL = "com.talkmos.app/ringtone"
        private const val PIP_CHANNEL = "com.talkmos.app/pip"
        private const val SCREEN_SHARE_CHANNEL = "com.talkmos.app/screen_share"
        private const val CALL_SERVICE_CHANNEL = "com.talkmos.app/call_service"
        private const val DEVICE_ID_CHANNEL = "com.talkmos.app/device_id"
        private const val KEEP_AWAKE_CHANNEL = "com.talkmos.app/keep_awake"
        private const val PROXIMITY_CHANNEL = "com.talkmos.app/proximity"
        private const val FSI_CHANNEL = "com.talkmos.app/full_screen_intent"
        private const val RINGTONE_PICKER_REQUEST = 4711
        private const val SCREEN_SHARE_START_TIMEOUT_MS = 5_000L

        /// The engine is kept here rather than owned by this Activity, so a
        /// call survives the Activity being destroyed — by a swipe out of
        /// recents, most of all. CallForegroundService is what keeps the
        /// process (and therefore this engine) alive once that happens.
        private const val ENGINE_ID = "talkmos_engine"

        // Broadcast used for the real system PiP window's own action
        // buttons (see buildPipActions()) — Android delivers a tap on one
        // of those by firing the RemoteAction's PendingIntent, which is this
        // same-app broadcast carrying which button was pressed.
        private const val PIP_ACTION_INTENT = "com.talkmos.app.PIP_ACTION"
        private const val PIP_ACTION_EXTRA = "pip_action"
        private const val PIP_ACTION_MUTE = "mute"
        private const val PIP_ACTION_SPEAKER = "speaker"
        private const val PIP_ACTION_HANGUP = "hangup"

        /// Static so a recreated Activity re-applies it to its new
        /// window — Dart only pushes this on a call-state change.
        private var keepScreenOnRequested = false
    }

    private var callEventsChannel: MethodChannel? = null
    private var pipChannel: MethodChannel? = null
    private var pipActionReceiver: BroadcastReceiver? = null

    // Kept in sync from Dart (see PipService) every time CallSignalingService's
    // state changes, so onUserLeaveHint below — which fires the instant the
    // user hits Home or switches apps — knows whether to shrink into a real
    // system PiP window without having to ask Dart and wait for a reply, and
    // so the PiP action buttons' icons (mic/speaker) match the real state.
    private var isCallActive = false
    private var isVideoCall = false
    private var isMicMuted = false
    private var isSpeakerOn = false

    /// Held while the system ringtone picker is open so its result can be
    /// handed back to the Dart caller that opened it.
    private var pendingRingtoneResult: MethodChannel.Result? = null

    override fun provideFlutterEngine(context: Context): FlutterEngine {
        FlutterEngineCache.getInstance().get(ENGINE_ID)?.let { return it }

        val engine = FlutterEngine(context.applicationContext)
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        FlutterEngineCache.getInstance().put(ENGINE_ID, engine)
        return engine
    }

    /// Never — the whole point of caching it is that it stays up when this
    /// Activity goes away.
    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        callEventsChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CALL_EVENTS_CHANNEL)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CALL_ACTIVITY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchCallActivity" -> {
                    try {
                        val callId = call.argument<String>("callId")
                        val callerId = call.argument<String>("callerId")
                        val callerName = call.argument<String>("callerName")
                        val callType = call.argument<String>("callType")

                        val intent = Intent(this, CallActivity::class.java).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                            putExtra("callId", callId)
                            putExtra("callerId", callerId)
                            putExtra("callerName", callerName)
                            putExtra("callType", callType)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("LAUNCH_FAILED", e.message, null)
                    }
                }
                "finishCallActivity" -> {
                    try {
                        CallActivity.activeInstance?.finish()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("FINISH_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RINGTONE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // The phone's currently configured default tone for a given
                // purpose. `type` picks which: "notification" for the short
                // alert a message should make, "ringtone" for the tune a call
                // rings with. Sending the ringtone back for a message sound
                // lands a 30-second loop on every incoming chat.
                "getSystemRingtone" -> {
                    try {
                        val ringtoneType = if (call.argument<String>("type") == "notification") {
                            RingtoneManager.TYPE_NOTIFICATION
                        } else {
                            RingtoneManager.TYPE_RINGTONE
                        }
                        val uri = RingtoneManager.getActualDefaultRingtoneUri(this, ringtoneType)
                            ?: RingtoneManager.getDefaultUri(ringtoneType)
                        result.success(mapOf(
                            "uri" to uri?.toString(),
                            "title" to titleForRingtone(uri)
                        ))
                    } catch (e: Exception) {
                        result.error("RINGTONE_FAILED", e.message, null)
                    }
                }
                "getRingtoneTitle" -> {
                    val raw = call.argument<String>("uri")
                    val uri = if (raw.isNullOrEmpty()) null else android.net.Uri.parse(raw)
                    result.success(titleForRingtone(uri))
                }
                // Opens the OS ringtone picker, which lists the system
                // ringtones plus anything the user has added. Its URIs are
                // already readable by the notification manager, unlike an
                // arbitrary file pick.
                "pickRingtone" -> {
                    if (pendingRingtoneResult != null) {
                        result.error("PICKER_BUSY", "A ringtone picker is already open", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val current = call.argument<String>("currentUri")
                        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
                            putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_RINGTONE)
                            putExtra(RingtoneManager.EXTRA_RINGTONE_TITLE, "Select call ringtone")
                            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
                            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
                            if (!current.isNullOrEmpty()) {
                                putExtra(
                                    RingtoneManager.EXTRA_RINGTONE_EXISTING_URI,
                                    android.net.Uri.parse(current)
                                )
                            }
                        }
                        pendingRingtoneResult = result
                        startActivityForResult(intent, RINGTONE_PICKER_REQUEST)
                    } catch (e: Exception) {
                        pendingRingtoneResult = null
                        result.error("PICKER_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        pipChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PIP_CHANNEL)
        pipChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateCallState" -> {
                    isCallActive = call.argument<Boolean>("active") ?: false
                    isVideoCall = call.argument<Boolean>("isVideo") ?: false
                    isMicMuted = call.argument<Boolean>("isMicMuted") ?: false
                    isSpeakerOn = call.argument<Boolean>("isSpeakerOn") ?: false
                    refreshPipActionsIfNeeded()
                    result.success(null)
                }
                // Explicit minimize action (e.g. leaving ActiveCallScreen while
                // still inside the app) — onUserLeaveHint only fires when the
                // whole app is backgrounded, so this is the hook for entering
                // PiP without leaving Talkmos at all.
                "enterPip" -> result.success(tryEnterPip())
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CALL_SERVICE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    try {
                        ContextCompat.startForegroundService(
                            this,
                            Intent(this, CallForegroundService::class.java)
                        )
                        result.success(null)
                    } catch (e: Exception) {
                        // A call that cannot hold the process up is still a
                        // call — report it and carry on rather than failing it.
                        Log.e(TAG, "call foreground service failed to start", e)
                        result.error("call_service", e.message, null)
                    }
                }
                "stop" -> {
                    stopService(Intent(this, CallForegroundService::class.java))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCREEN_SHARE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // Dart calls this right after flutter_webrtc's own
                // Helper.requestCapturePermission() grants consent, and
                // right before the actual capture starts — see
                // toggle_screen_share.dart for why that exact ordering
                // matters on Android 14+.
                "start" -> startScreenShareService(result)
                "stop" -> {
                    stopService(Intent(this, ScreenShareForegroundService::class.java))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // ANDROID_ID is scoped to this app's signing key on this device and
        // outlives an uninstall, unlike anything Dart can persist itself —
        // see DeviceInfoService for why the session id has to survive that.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEVICE_ID_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstallId" -> {
                    try {
                        result.success(
                            Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
                        )
                    } catch (e: Exception) {
                        result.error("DEVICE_ID_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // The Flutter call UI runs in this Activity, so nothing here holds the
        // screen awake by itself — a video call with no touches hits the system
        // screen timeout and blanks mid-call. See KeepAwakeService.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, KEEP_AWAKE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setEnabled" -> {
                    keepScreenOnRequested = call.arguments as? Boolean ?: false
                    applyKeepScreenOn()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PROXIMITY_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setEnabled" -> {
                    // The application context, not this Activity: the lock
                    // outlives the screen it was taken for.
                    ProximityLock.setEnabled(
                        applicationContext,
                        call.arguments as? Boolean ?: false
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, FSI_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // Whether an incoming call may take over the screen. Denied,
                // Android quietly downgrades the ring to a heads-up banner:
                // the phone makes a noise and the screen stays dark.
                "canUseFullScreenIntent" -> {
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                        result.success(true)
                    } else {
                        val manager = getSystemService(NotificationManager::class.java)
                        result.success(manager?.canUseFullScreenIntent() ?: false)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Handle any pending call action intent passed at startup
        intent?.let { handleCallActionIntent(it) }
    }

    /// Brings ScreenShareForegroundService up, answering Dart only once it is
    /// actually in the foreground. startForegroundService() merely queues the
    /// start, and a MediaProjection that begins before the service arrives is
    /// refused outright ("Media projections require a foreground service...").
    private fun startScreenShareService(result: MethodChannel.Result) {
        if (ScreenShareForegroundService.isForeground) {
            result.success(null)
            return
        }

        var answered = false
        val answer: (String?) -> Unit = { error ->
            if (!answered) {
                answered = true
                ScreenShareForegroundService.onForeground = null
                if (error == null) result.success(null)
                else result.error("screen_share_service", error, null)
            }
        }

        ScreenShareForegroundService.onForeground = { answer(null) }
        try {
            ContextCompat.startForegroundService(
                this,
                Intent(this, ScreenShareForegroundService::class.java)
            )
        } catch (e: Exception) {
            Log.e(TAG, "screen-share service failed to start", e)
            answer(e.message ?: "the screen-share service could not be started")
            return
        }
        // Rather than leave the caller waiting on a service that never arrives.
        Handler(Looper.getMainLooper()).postDelayed(
            { answer("the screen-share service did not start") },
            SCREEN_SHARE_START_TIMEOUT_MS
        )
    }

    /// Shrinks the Activity into a real system Picture-in-Picture window.
    /// No-ops (returns false) below API 26, where the PiP APIs don't exist —
    /// ActiveCallVideoPip's in-app floating window covers that case instead.
    private fun tryEnterPip(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        return try {
            val builder = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(9, 16))
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                builder.setActions(buildPipActions())
            }
            enterPictureInPictureMode(builder.build())
        } catch (e: Exception) {
            false
        }
    }

    /// The real PiP window has no way to reach Flutter's own widgets — a
    /// system PiP window only forwards a tap-to-expand gesture to the
    /// underlying app, nothing else — so mute/speaker/hang-up have to be
    /// Android's own PiP "actions": small icon buttons the OS itself draws
    /// on the PiP chrome, delivered back to the app as one of these
    /// PendingIntent broadcasts.
    private fun buildPipActions(): ArrayList<RemoteAction> {
        val actions = ArrayList<RemoteAction>()
        actions.add(
            RemoteAction(
                PipActionIcons.mic(isMicMuted),
                if (isMicMuted) "Unmute" else "Mute",
                if (isMicMuted) "Unmute" else "Mute",
                pipActionPendingIntent(PIP_ACTION_MUTE, 101)
            )
        )
        actions.add(
            RemoteAction(
                PipActionIcons.speaker(isSpeakerOn),
                if (isSpeakerOn) "Speaker off" else "Speaker on",
                if (isSpeakerOn) "Speaker off" else "Speaker on",
                pipActionPendingIntent(PIP_ACTION_SPEAKER, 102)
            )
        )
        actions.add(
            RemoteAction(
                PipActionIcons.hangUp(),
                "End call",
                "End call",
                pipActionPendingIntent(PIP_ACTION_HANGUP, 103)
            )
        )
        return actions
    }

    private fun pipActionPendingIntent(action: String, requestCode: Int): PendingIntent {
        val intent = Intent(PIP_ACTION_INTENT).apply {
            setPackage(packageName)
            putExtra(PIP_ACTION_EXTRA, action)
        }
        return PendingIntent.getBroadcast(
            this, requestCode, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    /// Re-sent whenever mic/speaker state changes (see updateCallState)
    /// while already in PiP, so the action icons stay in sync with reality
    /// instead of freezing at whatever they were when PiP was entered.
    private fun refreshPipActionsIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        if (!isInPictureInPictureMode) return
        try {
            setPictureInPictureParams(
                PictureInPictureParams.Builder().setActions(buildPipActions()).build()
            )
        } catch (e: Exception) {
            // Best-effort — a stale icon isn't worth crashing over.
        }
    }

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (isCallActive && isVideoCall) {
            tryEnterPip()
        }
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        pipChannel?.invokeMethod("onPipModeChanged", isInPictureInPictureMode)
    }

    /// Human-readable name for a ringtone URI, for display in settings.
    private fun titleForRingtone(uri: android.net.Uri?): String {
        if (uri == null) return "Silent"
        return try {
            RingtoneManager.getRingtone(this, uri)?.getTitle(this) ?: "Ringtone"
        } catch (e: Exception) {
            "Ringtone"
        }
    }

    /// A channel's sound is played by the system, out of the notification
    /// manager's own process — so a `content://` tone the picker returns has to
    /// be readable there too. Without this the channel is created pointing at a
    /// URI the system can't open, and quietly rings with the default tone
    /// instead of the one that was picked.
    private fun grantRingtoneAccess(uri: android.net.Uri) {
        for (target in listOf("com.android.systemui", "android")) {
            try {
                grantUriPermission(target, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            } catch (e: Exception) {
                Log.w(TAG, "grantUriPermission($target) failed: ${e.message}")
            }
        }
        try {
            contentResolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION
            )
        } catch (e: Exception) {
            // Only document-provider URIs are persistable; media ones are not.
            Log.d(TAG, "takePersistableUriPermission skipped: ${e.message}")
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != RINGTONE_PICKER_REQUEST) return

        val result = pendingRingtoneResult ?: return
        pendingRingtoneResult = null

        if (resultCode != RESULT_OK) {
            // User backed out — null tells Dart to keep the existing choice.
            result.success(null)
            return
        }

        val uri = data?.getParcelableExtra<android.net.Uri>(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
        if (uri == null) {
            result.success(null)
            return
        }
        grantRingtoneAccess(uri)
        result.success(mapOf("uri" to uri.toString(), "title" to titleForRingtone(uri)))
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleCallActionIntent(intent)
    }

    private fun handleCallActionIntent(intent: Intent) {
        val action = intent.action ?: return
        when (action) {
            SELECT_NOTIFICATION -> launchRingingScreenIfIncomingCall(intent)
            CallActivity.ACTION_ACCEPT -> {
                val callId = intent.getStringExtra("callId") ?: ""
                val callerId = intent.getStringExtra("callerId") ?: ""
                val callerName = intent.getStringExtra("callerName") ?: ""
                val callType = intent.getStringExtra("callType") ?: "audio"

                callEventsChannel?.invokeMethod("onCallAccepted", mapOf(
                    "callId" to callId,
                    "callerId" to callerId,
                    "callerName" to callerName,
                    "callType" to callType
                ))
            }
            CallActivity.ACTION_DECLINE -> {
                val callId = intent.getStringExtra("callId") ?: ""
                callEventsChannel?.invokeMethod("onCallDeclined", mapOf(
                    "callId" to callId
                ))
            }
        }
    }

    /// Opens the ringing screen for a call notification the system just
    /// launched us from.
    ///
    /// flutter_local_notifications points its full-screen intent at whatever
    /// activity has the LAUNCHER filter — this one — and gives no way to
    /// target another. So when Android fires the FSI (device locked, or the
    /// screen off) it starts MainActivity, which has no `showWhenLocked` and
    /// therefore sits behind the keyguard: the user gets a lock screen with a
    /// notification on it, never the call UI. CallActivity is the one that's
    /// allowed over the keyguard, so it has to be started from here.
    ///
    /// Being an activity start from an activity the system itself just
    /// launched, this is exempt from the background-activity-start rules.
    /// Handled natively rather than in Dart so it doesn't wait out a cold
    /// start before the phone shows who is calling.
    ///
    /// Only `SELECT_NOTIFICATION` reaches this — the plugin tags Accept with
    /// `SELECT_FOREGROUND_NOTIFICATION` instead, so answering from the
    /// notification doesn't get bounced into the ringing screen it just left.
    private fun launchRingingScreenIfIncomingCall(intent: Intent) {
        val payload = intent.getStringExtra(NOTIFICATION_PAYLOAD_EXTRA) ?: return
        try {
            val json = JSONObject(payload)
            // Chat/friend-request payloads and the ongoing-call notification
            // all come through here too; only a ringing call opens this screen.
            if (json.optString("kind") != "incoming") return

            val callId = json.optString("callId")
            if (callId.isEmpty()) return

            // The activity's intent outlives the call that created it — a
            // process restart would otherwise replay this and flash up a
            // ringing screen for a call that ended long ago.
            if (!CallActivity.isIncomingCallNotificationActive(this)) return

            startActivity(Intent(this, CallActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("callId", callId)
                putExtra("callerId", json.optString("callerId"))
                putExtra("callerName", json.optString("callerName"))
                putExtra("callType", json.optString("callType").ifEmpty { "audio" })
            })
        } catch (e: Exception) {
            Log.w(TAG, "Could not open ringing screen from notification: ${e.message}")
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()

        pipActionReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                val action = intent.getStringExtra(PIP_ACTION_EXTRA) ?: return
                pipChannel?.invokeMethod("onPipAction", action)
            }
        }
        val filter = IntentFilter(PIP_ACTION_INTENT)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(pipActionReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(pipActionReceiver, filter)
        }
    }

    override fun onResume() {
        super.onResume()
        applyKeepScreenOn()
    }

    private fun applyKeepScreenOn() {
        if (keepScreenOnRequested) {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }

    override fun onDestroy() {
        pipActionReceiver?.let { unregisterReceiver(it) }
        pipActionReceiver = null
        super.onDestroy()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = getSystemService(NotificationManager::class.java)

            // Message notifications are posted on a sound-specific channel the
            // Dart side owns (MessageNotifier.channelIdPrefix + the tone), so
            // this bare "talkmos_messages" one only ever sat unused in system
            // settings next to the real one.
            notificationManager.deleteNotificationChannel("talkmos_messages")

            // The incoming-call channel is owned by the Dart side
            // (CallNotificationService), which recreates it under a new id
            // whenever the user picks a different ringtone — a channel's sound
            // is immutable once created. This removes the older duplicate that
            // used to be declared here, so system settings doesn't show two
            // "Incoming Calls" entries.
            notificationManager.deleteNotificationChannel("talkmos_calls")

            // One-time cleanup of the pre-v2 incoming-call channel ids (see
            // CallNotificationService._channelIdPrefix) — a channel any of
            // these got muted/downgraded on stays that way forever otherwise,
            // since the id never changed across every earlier app update.
            notificationManager.deleteNotificationChannel("talkmos_incoming_calls_r_call_ringtone")
            notificationManager.deleteNotificationChannel("talkmos_incoming_calls_r_dbsui")
        }
    }
}
