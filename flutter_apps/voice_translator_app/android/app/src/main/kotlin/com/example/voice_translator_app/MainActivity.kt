package com.example.voice_translator_app

import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.media.ToneGenerator
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var ringtonePlayer: MediaPlayer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "voice_translator_app/ringtone"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    startRingtone()
                    result.success(null)
                }
                "stop" -> {
                    stopRingtone()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "voice_translator_app/call_audio"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "ringingBeep" -> {
                    playTone(ToneGenerator.TONE_SUP_RINGTONE, 180)
                    result.success(null)
                }
                "connected" -> {
                    playTone(ToneGenerator.TONE_PROP_ACK, 220)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onStop() {
        stopRingtone()
        super.onStop()
    }

    private fun startRingtone() {
        stopRingtone()

        val ringtoneUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
            ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            ?: return

        val player = MediaPlayer()
        try {
            player.setDataSource(applicationContext, ringtoneUri)
            player.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build()
            )
            player.isLooping = true
            player.prepare()
            player.start()
            ringtonePlayer = player
        } catch (error: Exception) {
            player.release()
        }
    }

    private fun stopRingtone() {
        ringtonePlayer?.run {
            if (isPlaying) stop()
            release()
        }
        ringtonePlayer = null
    }

    private fun playTone(toneType: Int, durationMs: Int) {
        val toneGenerator = ToneGenerator(AudioManager.STREAM_MUSIC, 72)
        toneGenerator.startTone(toneType, durationMs)
        window.decorView.postDelayed({ toneGenerator.release() }, durationMs + 120L)
    }
}
