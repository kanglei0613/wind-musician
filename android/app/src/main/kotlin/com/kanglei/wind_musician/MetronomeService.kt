package com.kanglei.wind_musician

import android.app.Service
import android.content.Intent
import android.os.Binder
import android.os.IBinder
import android.os.PowerManager
import android.media.AudioManager

/**
 * MetronomeService
 *
 * Android 前景服務（Foreground Service），負責：
 *   1. 在 App 切至背景後維持節拍器運行（透過前景服務持有優先級）
 *   2. 顯示持續通知，符合 Android 前景服務規定
 *   3. 持有 PARTIAL_WAKE_LOCK，確保螢幕關閉時 CPU 繼續執行排程
 *   4. 管理 AudioFocus，避免被其他 App（如螢幕錄影工具）搶走音訊
 *   5. 透過 Binder 讓 MainActivity 呼叫 start/stop/update 指令
 *
 * 服務生命週期：
 *   MainActivity.startForegroundService(intent) → onCreate → onBind
 *   命令到達 → onStartCommand（處理 ACTION_START / ACTION_STOP）
 *   unbind + stop → onDestroy → 釋放所有資源
 */
class MetronomeService : Service() {

    // ── Binder（讓 Activity 直接呼叫方法）────────────────────────────────
    inner class MetronomeBinder : Binder() {
        fun getService(): MetronomeService = this@MetronomeService
    }

    private val binder = MetronomeBinder()

    // ── 核心元件 ──────────────────────────────────────────────────────────
    private lateinit var engine: MetronomeEngine
    private lateinit var audioFocusHandler: AudioFocusHandler

    /** WakeLock：防止 CPU 在螢幕關閉後休眠，維持高精度排程 */
    private var wakeLock: PowerManager.WakeLock? = null

    // ── 當前狀態（用於更新通知） ──────────────────────────────────────────
    private var currentBpm: Int = 120
    private var currentNumerator: Int = 4
    private var currentDenominator: Int = 4

    // ── 外部回呼：節拍事件 → MainActivity → Flutter ────────────────────────
    /**
     * 每拍觸發一次，由 MainActivity 設定。
     * 此回呼在 MetronomeEngine 的 audioThread 上執行。
     */
    var onBeatCallback: (() -> Unit)? = null

    /**
     * AudioFocus 變化回呼，由 MainActivity 設定。
     * 參數為 AudioManager.AUDIOFOCUS_* 常數整數值。
     * MainActivity 透過此回呼將焦點事件轉發至 Flutter audio_focus channel。
     */
    var onAudioFocusChangeCallback: ((Int) -> Unit)? = null

    // ── 服務生命週期 ──────────────────────────────────────────────────────

    override fun onCreate() {
        super.onCreate()

        // 建立通知頻道（Android 8+）
        NotificationHelper.createChannel(this)

        // 建立引擎，每拍時觸發回呼
        engine = MetronomeEngine {
            onBeatCallback?.invoke()
        }

        // 建立 AudioFocus 處理器
        audioFocusHandler = AudioFocusHandler(this) { focusChange ->
            handleAudioFocusChange(focusChange)
        }
    }

    override fun onBind(intent: Intent?): IBinder = binder

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // START_STICKY：服務被系統殺死後自動重啟（對節拍器來說通常不需要，但保留）
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        stopMetronome()
        engine.release()
        super.onDestroy()
    }

    // ── 公開控制方法（由 MainActivity 透過 Binder 呼叫）──────────────────

    /**
     * 啟動節拍器前景服務。
     *
     * 流程：
     *   1. 請求 AudioFocus
     *   2. 取得 WakeLock
     *   3. 啟動前景服務（顯示通知）
     *   4. 啟動引擎
     *
     * @param bpm        BPM
     * @param numerator  拍號分子
     * @param denominator 拍號分母
     */
    fun startMetronome(bpm: Int, numerator: Int, denominator: Int) {
        currentBpm = bpm
        currentNumerator = numerator
        currentDenominator = denominator

        // ① 請求 AudioFocus（即使失敗也繼續播放，僅記錄）
        val granted = audioFocusHandler.requestFocus()
        if (!granted) {
            android.util.Log.w("MetronomeService", "AudioFocus 請求被拒，繼續播放")
        }

        // ② 取得 WakeLock（PARTIAL_WAKE_LOCK：CPU 運行，螢幕可關閉）
        if (wakeLock == null) {
            val pm = getSystemService(POWER_SERVICE) as PowerManager
            wakeLock = pm.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "WindMusician:MetronomeWakeLock"
            ).apply {
                // 設定最長持有 3 小時，防止意外洩漏（正常情況下會由 stopMetronome 釋放）
                acquire(3 * 60 * 60 * 1000L)
            }
        }

        // ③ 啟動前景服務（必須在 5 秒內呼叫 startForeground，否則 ANR）
        val notification = NotificationHelper.buildNotification(
            this,
            bpm,
            "$numerator/$denominator"
        )
        startForeground(NotificationHelper.NOTIFICATION_ID, notification)

        // ④ 啟動引擎
        engine.start(bpm, numerator, denominator)
    }

    /**
     * 停止節拍器並釋放所有資源。
     */
    fun stopMetronome() {
        engine.stop()

        // 釋放 AudioFocus
        audioFocusHandler.abandonFocus()

        // 釋放 WakeLock
        wakeLock?.let {
            if (it.isHeld) it.release()
        }
        wakeLock = null

        // 停止前景服務（移除通知）
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    /**
     * 更新 BPM（節拍器運行中可呼叫）。
     */
    fun updateBpm(newBpm: Int) {
        currentBpm = newBpm
        engine.updateBpm(newBpm)
        // 更新通知顯示
        NotificationHelper.updateNotification(
            this, currentBpm, "$currentNumerator/$currentDenominator"
        )
    }

    /**
     * 更新拍號（節拍器運行中可呼叫）。
     */
    fun updateTimeSig(numerator: Int, denominator: Int) {
        currentNumerator = numerator
        currentDenominator = denominator
        engine.updateTimeSig(numerator, denominator)
        // 更新通知顯示
        NotificationHelper.updateNotification(
            this, currentBpm, "$numerator/$denominator"
        )
    }

    /**
     * 切換音色（運行中可呼叫，AudioTrack 在 audioThread 熱替換）。
     *
     * @param soundType  "SINE" | "WOODBLOCK" | "STICK_CLICK" | "SNARE"
     */
    fun setSoundType(soundType: String) {
        val type = try {
            SoundType.valueOf(soundType.uppercase())
        } catch (_: IllegalArgumentException) {
            SoundType.SINE
        }
        engine.setSoundType(type)
    }

    /**
     * 切換音高變體（1~5）。
     */
    fun setPitchVariant(variant: Int) {
        engine.setPitchVariant(variant)
    }

    // ── 內部處理 ──────────────────────────────────────────────────────────

    /**
     * 處理 AudioFocus 變化（由 AudioFocusHandler 回呼）。
     *
     * 策略：
     *   - LOSS / LOSS_TRANSIENT  → 暫停引擎（通知 Flutter 更新 UI）
     *   - GAIN                   → 重新啟動引擎
     *   - LOSS_TRANSIENT_CAN_DUCK → 保持播放（節拍器不適合降音量繼續）
     *
     * 注意：此方法在 AudioManager 的執行緒上呼叫，需避免 UI 操作。
     */
    private fun handleAudioFocusChange(focusChange: Int) {
        when (focusChange) {
            AudioManager.AUDIOFOCUS_GAIN -> {
                // 重新取得焦點（例如來電結束後），重啟引擎
                android.util.Log.d("MetronomeService", "AudioFocus 恢復：重啟引擎")
                engine.start(currentBpm, currentNumerator, currentDenominator)
            }
            AudioManager.AUDIOFOCUS_LOSS,
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                // 失去焦點：暫停引擎，避免與其他 App 音訊衝突
                android.util.Log.d("MetronomeService", "AudioFocus 失去 ($focusChange)：暫停引擎")
                engine.stop()
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                // 可以繼續播放（系統建議降低音量），節拍器保持全音量繼續
                android.util.Log.d("MetronomeService", "AudioFocus Duck：維持播放")
            }
        }
        // 通知 MainActivity 轉發此事件至 Flutter audio_focus channel
        onAudioFocusChangeCallback?.invoke(focusChange)
    }
}
