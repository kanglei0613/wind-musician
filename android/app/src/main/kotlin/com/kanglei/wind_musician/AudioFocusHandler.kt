package com.kanglei.wind_musician

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build

/**
 * AudioFocusHandler
 *
 * 管理 Android AudioFocus（音訊焦點）的請求、釋放與監聽。
 *
 * 使用場景：
 *   - 螢幕錄影工具（如 AZ Screen Recorder）啟動時會搶走 AudioFocus，
 *     導致節拍器音效消失。此類別負責：
 *       1. 節拍器啟動時向系統請求 AUDIOFOCUS_GAIN
 *       2. 監聽 AudioFocus 變化，透過回呼通知 Flutter 層
 *       3. 節拍器停止時釋放焦點
 *
 * AudioFocus 策略（onFocusChange）：
 *   GAIN                → 恢復全音量（其他 App 已放棄焦點）
 *   LOSS                → 永久失去焦點（例如音樂 App 啟動），通知 Flutter 暫停
 *   LOSS_TRANSIENT      → 短暫失去（例如來電），通知 Flutter 暫停
 *   LOSS_TRANSIENT_CAN_DUCK → 可壓低音量（例如導航語音），保持播放但降音量
 *
 * @param context        應用程式 Context
 * @param onFocusChange  焦點變化回呼，參數為 AudioManager 的 AUDIOFOCUS_* 常數
 */
class AudioFocusHandler(
    context: Context,
    private val onFocusChange: (Int) -> Unit
) {

    private val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    /** Android 8.0+ 的 AudioFocusRequest 物件（舊版 API 不需要） */
    private var focusRequest: AudioFocusRequest? = null

    /** 焦點變化監聽器（舊版 API 和新版 API 共用相同的邏輯） */
    private val focusListener = AudioManager.OnAudioFocusChangeListener { focusChange ->
        onFocusChange(focusChange)
    }

    /**
     * 向系統請求 AudioFocus（節拍器開始播放時呼叫）。
     *
     * 請求類型：AUDIOFOCUS_GAIN
     *   - 表示此 App 需要長時間持有焦點（適合節拍器）
     *   - 其他 App 可能因此被暫停或降低音量
     *
     * @return true 表示成功取得焦點（AUDIOFOCUS_REQUEST_GRANTED），
     *         false 表示被拒絕（AUDIOFOCUS_REQUEST_FAILED）
     */
    fun requestFocus(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // Android 8.0+ 使用 AudioFocusRequest
            val request = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
                .setAcceptsDelayedFocusGain(false)  // 不接受延遲授予（需要立即獲得）
                .setOnAudioFocusChangeListener(focusListener)
                .build()

            focusRequest = request
            val result = audioManager.requestAudioFocus(request)
            result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        } else {
            // Android 8.0 以下使用舊版 API
            @Suppress("DEPRECATION")
            val result = audioManager.requestAudioFocus(
                focusListener,
                AudioManager.STREAM_MUSIC,
                AudioManager.AUDIOFOCUS_GAIN
            )
            result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED
        }
    }

    /**
     * 釋放 AudioFocus（節拍器停止時呼叫）。
     * 釋放後其他 App 可重新取得焦點並恢復播放。
     */
    fun abandonFocus() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            focusRequest?.let { audioManager.abandonAudioFocusRequest(it) }
            focusRequest = null
        } else {
            @Suppress("DEPRECATION")
            audioManager.abandonAudioFocus(focusListener)
        }
    }
}
