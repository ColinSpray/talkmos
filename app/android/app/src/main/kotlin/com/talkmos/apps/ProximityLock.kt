package com.talkmos.apps

import android.content.Context
import android.os.PowerManager
import android.util.Log

/// Blanks the screen while the phone is against the ear, the way the dialler
/// does — and, just as importantly, stops a cheek from hanging up the call.
///
/// Only worth holding while the call is on the earpiece: on speaker, or on
/// video, the user is looking at the screen.
object ProximityLock {
    private const val TAG = "TalkmosProximity"

    private var lock: PowerManager.WakeLock? = null

    fun setEnabled(context: Context, enabled: Boolean) {
        val power = context.getSystemService(Context.POWER_SERVICE) as? PowerManager ?: return
        if (enabled) acquire(power) else release()
    }

    private fun acquire(power: PowerManager) {
        if (lock?.isHeld == true) return
        if (!power.isWakeLockLevelSupported(PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK)) {
            Log.i(TAG, "this device has no proximity wake lock")
            return
        }
        try {
            val acquired = power.newWakeLock(
                PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK,
                "talkmos:call_proximity"
            )
            acquired.setReferenceCounted(false)
            acquired.acquire()
            lock = acquired
        } catch (e: Exception) {
            Log.e(TAG, "could not acquire the proximity lock", e)
        }
    }

    private fun release() {
        val held = lock ?: return
        lock = null
        try {
            // Waits for the phone to come away from the ear before letting the
            // screen back on, rather than flashing it into the user's face.
            held.release(PowerManager.RELEASE_FLAG_WAIT_FOR_NO_PROXIMITY)
        } catch (e: Exception) {
            Log.e(TAG, "could not release the proximity lock", e)
        }
    }
}
