package com.talkmos.apps

import android.animation.Animator
import android.animation.ObjectAnimator
import android.animation.ValueAnimator
import android.app.Activity
import android.app.KeyguardManager
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.WindowManager
import android.view.animation.AccelerateDecelerateInterpolator
import android.view.animation.DecelerateInterpolator
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView

class CallActivity : Activity() {

    companion object {
        const val ACTION_ACCEPT = "com.talkmos.apps.ACTION_ACCEPT_CALL"
        const val ACTION_DECLINE = "com.talkmos.apps.ACTION_DECLINE_CALL"
        var activeInstance: CallActivity? = null

        // Mirrors CallNotificationService._incomingNotificationId in
        // lib/features/calls/services/call_notification_service.dart — keep
        // the two in sync if that ever changes.
        private const val INCOMING_CALL_NOTIFICATION_ID = 991100

        private const val NOTIFICATION_POLL_INTERVAL_MS = 1000L

        // One sonar ring every PULSE_DURATION_MS, the second launched half a
        // cycle behind the first so the rings are always evenly spaced.
        private const val PULSE_DURATION_MS = 2000L
        private const val PULSE_MAX_SCALE = 1.62f
        private const val PULSE_START_ALPHA = 0.5f

        /// Whether the incoming-call notification is on screen right now, i.e.
        /// whether there is still a call ringing for this screen to show.
        /// Shared with MainActivity, which uses it to decide whether a
        /// notification intent it's replaying is a live call or a stale one.
        fun isIncomingCallNotificationActive(context: Context): Boolean {
            return try {
                val manager = context.getSystemService(Context.NOTIFICATION_SERVICE)
                    as? NotificationManager ?: return true
                manager.activeNotifications.any { it.id == INCOMING_CALL_NOTIFICATION_ID }
            } catch (e: Exception) {
                // Some OEM skins restrict this API — don't let a lookup failure
                // finish (or suppress) a screen that's still legitimately ringing.
                true
            }
        }
    }

    private var callId: String? = null
    private var callerId: String? = null
    private var callerName: String? = null
    private var callType: String? = null

    // Dart's finishCallActivity() (MainActivity's CALL_ACTIVITY_CHANNEL) is
    // the fast path when it lands. It doesn't always: a call the caller
    // cancels while this screen is still ringing is delivered from whichever
    // isolate the socket/FCM message happens to land in, and a background
    // isolate (the Firebase background handler, or flutter_local_notifications'
    // own background notification-response isolate) runs on a FlutterEngine
    // MainActivity never configured — that MethodChannel invoke has no native
    // listener there and is silently swallowed.
    //
    // The one signal that reliably reaches this screen regardless of which
    // isolate handled the server event is the incoming-call notification
    // itself: flutter_local_notifications is registered on every engine, so
    // cancelling it (CallNotificationService.endCall/endAllCalls) always
    // succeeds — that's why the notification-only case already worked. Poll
    // for it instead of trusting only the method channel.
    private val pollHandler = Handler(Looper.getMainLooper())
    private val pollNotificationDismissed = object : Runnable {
        override fun run() {
            if (!isNotificationStillActive()) {
                finish()
                return
            }
            pollHandler.postDelayed(this, NOTIFICATION_POLL_INTERVAL_MS)
        }
    }

    private fun isNotificationStillActive(): Boolean = isIncomingCallNotificationActive(this)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        activeInstance = this
        configureLockScreenFlags()
        setContentView(R.layout.activity_incoming_call)

        callId = intent.getStringExtra("callId")
        callerId = intent.getStringExtra("callerId")
        callerName = intent.getStringExtra("callerName") ?: getString(R.string.incoming_call_default_name)
        callType = intent.getStringExtra("callType") ?: "audio"

        val tvCallerName = findViewById<TextView>(R.id.tvCallerName)
        val tvCallType = findViewById<TextView>(R.id.tvCallType)
        val tvAvatarInitial = findViewById<TextView>(R.id.tvAvatarInitial)
        val ivCallTypeIcon = findViewById<ImageView>(R.id.ivCallTypeIcon)

        tvCallerName.text = callerName

        val isVideo = callType == "video"
        tvCallType.setText(
            if (isVideo) R.string.incoming_call_type_video else R.string.incoming_call_type_voice
        )
        ivCallTypeIcon.setImageResource(
            if (isVideo) R.drawable.ic_call_video else R.drawable.ic_call_answer
        )

        // Digits, emoji and other non-letters make a poor monogram — fall back
        // to the placeholder rather than putting "+" on the avatar.
        callerName?.firstOrNull { it.isLetter() }?.let {
            tvAvatarInitial.text = it.uppercase()
        }

        findViewById<LinearLayout>(R.id.btnAccept).setOnClickListener {
            onAcceptClicked()
        }

        findViewById<LinearLayout>(R.id.btnDecline).setOnClickListener {
            onDeclineClicked()
        }

        startRingingAnimations()
    }

    // ─── Ringing animations ─────────────────────────────────────────────────

    private val animators = mutableListOf<Animator>()

    // Two rings expanding out from under the avatar, plus a slow breath on
    // the Accept button. A ringing screen that sits perfectly still reads as
    // a frozen screenshot — especially on the lock screen, where this is the
    // only thing moving.
    private fun startRingingAnimations() {
        startPulse(findViewById(R.id.pulseRingOne), 0L)
        startPulse(findViewById(R.id.pulseRingTwo), PULSE_DURATION_MS / 2)

        val accept = findViewById<View>(R.id.btnAcceptCircle)
        listOf(View.SCALE_X, View.SCALE_Y).forEach { property ->
            ObjectAnimator.ofFloat(accept, property, 1f, 1.07f).apply {
                duration = 900
                repeatCount = ValueAnimator.INFINITE
                repeatMode = ValueAnimator.REVERSE
                interpolator = AccelerateDecelerateInterpolator()
                animators += this
                start()
            }
        }
    }

    private fun startPulse(ring: View, delay: Long) {
        ring.alpha = 0f
        listOf(
            ObjectAnimator.ofFloat(ring, View.SCALE_X, 1f, PULSE_MAX_SCALE),
            ObjectAnimator.ofFloat(ring, View.SCALE_Y, 1f, PULSE_MAX_SCALE),
            ObjectAnimator.ofFloat(ring, View.ALPHA, PULSE_START_ALPHA, 0f)
        ).forEach { animator ->
            animator.apply {
                duration = PULSE_DURATION_MS
                startDelay = delay
                repeatCount = ValueAnimator.INFINITE
                interpolator = DecelerateInterpolator()
                animators += this
                start()
            }
        }
    }

    private fun stopRingingAnimations() {
        animators.forEach { it.cancel() }
        animators.clear()
    }

    override fun onResume() {
        super.onResume()
        pollHandler.postDelayed(pollNotificationDismissed, NOTIFICATION_POLL_INTERVAL_MS)
    }

    override fun onPause() {
        pollHandler.removeCallbacks(pollNotificationDismissed)
        super.onPause()
    }

    override fun onDestroy() {
        pollHandler.removeCallbacks(pollNotificationDismissed)
        stopRingingAnimations()
        if (activeInstance == this) {
            activeInstance = null
        }
        super.onDestroy()
    }

    /// Shows this screen *over* the keyguard without unlocking anything.
    ///
    /// Deliberately no `requestDismissKeyguard` / `FLAG_DISMISS_KEYGUARD`
    /// here: on a secure lock screen both raise the PIN/pattern bouncer, so a
    /// ringing phone demanded the user's credentials before it would even
    /// show them who was calling. Answering is the one action that needs the
    /// device unlocked — see [onAcceptClicked].
    private fun configureLockScreenFlags() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }

        @Suppress("DEPRECATION")
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
        )

        // Let the backdrop run under the status/navigation bars — the layout
        // keeps its content clear of them with fitsSystemWindows, so this is
        // purely so the gradient reaches the edges instead of stopping at two
        // grey bands.
        window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT
    }

    /// Answering hands over to the Flutter call UI, which lives in
    /// MainActivity — an ordinary activity that is not allowed over the
    /// keyguard (and shouldn't be: that would put every chat in the app one
    /// tap away from a locked phone). So this is where the unlock is asked
    /// for. The accept itself is sent regardless of whether the user gets
    /// through the bouncer, so the call still connects and audio still flows
    /// on a phone left locked.
    private fun onAcceptClicked() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
            keyguardManager?.requestDismissKeyguard(this, null)
        }

        val acceptIntent = Intent(this, MainActivity::class.java).apply {
            action = ACTION_ACCEPT
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            putExtra("callId", callId)
            putExtra("callerId", callerId)
            putExtra("callerName", callerName)
            putExtra("callType", callType)
        }
        startActivity(acceptIntent)
        finish()
    }

    private fun onDeclineClicked() {
        val declineIntent = Intent(this, MainActivity::class.java).apply {
            action = ACTION_DECLINE
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            putExtra("callId", callId)
        }
        startActivity(declineIntent)
        finish()
    }
}
