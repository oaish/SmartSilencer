package com.smartsilencer.smart_silencer

import android.app.NotificationManager
import android.content.Context
import android.media.AudioManager
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.smartsilencer/audio"
    private val TAG = "SmartSilencerNative"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setRingerMode" -> {
                        val mode = call.argument<Int>("mode") ?: 2
                        setRingerMode(mode, result)
                    }
                    "getRingerMode" -> {
                        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                        result.success(audioManager.ringerMode)
                    }
                    "checkDnDPermission" -> {
                        result.success(isDnDPermissionGranted())
                    }
                    "openDnDSettings" -> {
                        openDnDSettings()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun isDnDPermissionGranted(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val granted = notificationManager.isNotificationPolicyAccessGranted
            Log.d(TAG, "isDnDPermissionGranted check: $granted")
            return granted
        }
        return true
    }

    private fun openDnDSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Log.d(TAG, "Opening DnD settings UI")
            val intent = android.content.Intent(
                android.provider.Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS
            )
            intent.flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(intent)
        }
    }

    private fun setRingerMode(mode: Int, result: MethodChannel.Result) {
        try {
            Log.d(TAG, "--- setRingerMode transition start ---")
            Log.d(TAG, "Requested mode: $mode (0=SILENT, 1=VIBRATE, 2=NORMAL)")
            
            if (!isDnDPermissionGranted()) {
                Log.w(TAG, "Transition aborted: DND permission missing")
                result.error(
                    "DND_PERMISSION",
                    "Do Not Disturb permission required.",
                    null
                )
                return
            }

            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            
            when (mode) {
                0 -> { // SILENT
                    Log.d(TAG, "Action: Setting to RINGER_MODE_SILENT")
                    audioManager.ringerMode = AudioManager.RINGER_MODE_SILENT
                    // Also mute streams explicitly for extra safety on custom ROMs
                    audioManager.setStreamVolume(AudioManager.STREAM_RING, 0, 0)
                    audioManager.setStreamVolume(AudioManager.STREAM_NOTIFICATION, 0, 0)
                }
                1 -> { // VIBRATE
                    Log.d(TAG, "Action: Setting to RINGER_MODE_VIBRATE")
                    audioManager.ringerMode = AudioManager.RINGER_MODE_VIBRATE
                }
                else -> { // NORMAL
                    Log.d(TAG, "Action: Setting to RINGER_MODE_NORMAL")
                    audioManager.ringerMode = AudioManager.RINGER_MODE_NORMAL
                    // Optionally restore some volume? Usually ringerMode change handles this.
                }
            }
            
            // Log final state
            val finalMode = audioManager.ringerMode
            Log.d(TAG, "Final RingerMode: $finalMode")
            Log.d(TAG, "--- transition end ---")
            
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Critical failure in setRingerMode", e)
            result.error("AUDIO_ERROR", e.message, null)
        }
    }
}
