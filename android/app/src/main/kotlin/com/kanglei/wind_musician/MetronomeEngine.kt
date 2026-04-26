package com.kanglei.wind_musician

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.os.Handler
import android.os.HandlerThread
import android.os.Process
import android.os.SystemClock
import kotlin.math.PI
import kotlin.math.roundToInt
import kotlin.math.sin

/**
 * MetronomeEngine
 *
 * 節拍器核心引擎，負責：
 *   1. 在高優先級 HandlerThread 上排程每一拍
 *   2. 以 AudioTrack（MODE_STATIC + PCM 短波形）播放打擊音
 *   3. 使用 SystemClock.elapsedRealtime() 做絕對時間補償，消除累積漂移
 *
 * 設計原則：
 *   - 不依賴 UI 執行緒，所有音訊操作均在 audioThread 執行
 *   - 每拍計算「應到時間 - 實際時間」作為下一個 Handler.postDelayed 的延遲
 *   - AudioTrack 使用 MODE_STATIC：波形預先寫入，play() 零延遲觸發
 *
 * @param onBeat  每拍回呼（在 audioThread 執行，由呼叫方負責切換執行緒）
 */
class MetronomeEngine(private val onBeat: () -> Unit) {

    // ── 音訊執行緒 ─────────────────────────────────────────────────────────
    /** 高優先級音訊執行緒（與系統音訊服務同優先級）*/
    private val audioThread = HandlerThread(
        "MetronomeAudioThread",
        Process.THREAD_PRIORITY_AUDIO
    ).also { it.start() }

    /** 綁定在 audioThread 上的 Handler，用於排程拍點 */
    private val handler = Handler(audioThread.looper)

    // ── 狀態 ──────────────────────────────────────────────────────────────
    @Volatile private var isRunning = false
    @Volatile private var bpm: Int = 120
    @Volatile private var numerator: Int = 4
    @Volatile private var denominator: Int = 4

    /** 播放起始的 elapsedRealtime（毫秒），用於計算每拍應到時間 */
    private var startElapsedMs: Long = 0L

    /** 已排程的拍序號（從 0 開始的強拍算第 0 拍） */
    private var scheduledBeatIndex: Int = 0

    // ── AudioTrack（預先建立，重複使用）────────────────────────────────────
    private val sampleRate = 44100

    /** 強拍 AudioTrack（880 Hz，較響） */
    private val strongTrack: AudioTrack = buildAudioTrack(880.0, 0.85f)

    /** 弱拍 AudioTrack（660 Hz，較輕） */
    private val weakTrack: AudioTrack = buildAudioTrack(660.0, 0.55f)

    // ── 公開介面 ──────────────────────────────────────────────────────────

    /**
     * 開始播放節拍器。
     * 若已在運行中則先停止再重新開始。
     *
     * @param initialBpm       BPM
     * @param initialNumerator 分子（每小節拍數）
     * @param initialDenominator 分母（幾分音符為一拍）
     */
    fun start(initialBpm: Int, initialNumerator: Int, initialDenominator: Int) {
        stop() // 確保舊的排程已清除
        bpm = initialBpm
        numerator = initialNumerator
        denominator = initialDenominator
        isRunning = true
        startElapsedMs = SystemClock.elapsedRealtime()
        scheduledBeatIndex = 0
        // 立即在 audioThread 上打第 0 拍，再排程下一拍
        handler.post { fireBeatAndScheduleNext() }
    }

    /**
     * 停止節拍器，移除所有待執行的 Runnable。
     */
    fun stop() {
        isRunning = false
        handler.removeCallbacksAndMessages(null)
    }

    /**
     * 動態更新 BPM（播放中可呼叫）。
     * 重置時間基準，避免舊間隔殘留。
     */
    fun updateBpm(newBpm: Int) {
        bpm = newBpm
        if (isRunning) resetTiming()
    }

    /**
     * 動態更新拍號（播放中可呼叫）。
     * 重置時間基準。
     */
    fun updateTimeSig(newNumerator: Int, newDenominator: Int) {
        numerator = newNumerator
        denominator = newDenominator
        if (isRunning) resetTiming()
    }

    /**
     * 釋放所有資源（服務銷毀時呼叫）。
     * 呼叫後此物件不可再使用。
     */
    fun release() {
        stop()
        audioThread.quit()
        releaseTrack(strongTrack)
        releaseTrack(weakTrack)
    }

    // ── 內部實作 ──────────────────────────────────────────────────────────

    /**
     * 重置時間基準（BPM 或拍號改變時呼叫）。
     * 從「現在」起重新計算每拍的到達時間。
     */
    private fun resetTiming() {
        handler.removeCallbacksAndMessages(null)
        startElapsedMs = SystemClock.elapsedRealtime()
        scheduledBeatIndex = 0
        handler.post { fireBeatAndScheduleNext() }
    }

    /**
     * 核心排程函式：播放本拍音效 → 回呼 Flutter → 排程下一拍。
     *
     * 絕對時間補償原理：
     *   intervalMs  = 60000 / bpm * (4 / denominator)   // 每拍毫秒數
     *   targetMs    = beatIndex * intervalMs             // 第 N 拍的「應到時間」
     *   elapsedMs   = now - startElapsedMs               // 實際已過時間
     *   delayMs     = targetMs - elapsedMs               // 距離下一拍的剩餘時間
     *
     * 若 delayMs < 0 代表已超時，立即執行（clamp to 0）。
     */
    private fun fireBeatAndScheduleNext() {
        if (!isRunning) return

        // ① 取得本拍在小節中的位置（0 = 強拍）
        val beatInMeasure = scheduledBeatIndex % numerator
        val isDownBeat = beatInMeasure == 0

        // ② 播放對應音效
        playClick(if (isDownBeat) strongTrack else weakTrack)

        // ③ 通知 Flutter UI（此回呼在 audioThread，Flutter 側需切換至 main isolate）
        onBeat()

        // ④ 計算下一拍的精確延遲
        val intervalMs = (60_000.0 / bpm) * (4.0 / denominator)
        scheduledBeatIndex++
        val targetMs = (scheduledBeatIndex * intervalMs).roundToInt().toLong()
        val elapsedMs = SystemClock.elapsedRealtime() - startElapsedMs
        // clamp(0, 2*interval)：防止極端情況導致連拍或過長停頓
        val delayMs = (targetMs - elapsedMs).coerceIn(0L, (intervalMs * 2).toLong())

        handler.postDelayed({ fireBeatAndScheduleNext() }, delayMs)
    }

    /**
     * 觸發 AudioTrack 播放（MODE_STATIC 需要先 stop + reloadStaticData + play）。
     *
     * MODE_STATIC 的限制：一個 AudioTrack 無法同時重疊播放，
     * 但節拍器的音效時長（~100ms）遠短於拍間隔，實務上不會衝突。
     */
    private fun playClick(track: AudioTrack) {
        try {
            track.stop()
            track.reloadStaticData()
            track.play()
        } catch (e: Exception) {
            // 忽略偶發的 IllegalStateException（App 切換背景時偶爾發生）
        }
    }

    /**
     * 建立預先填入 PCM 資料的 AudioTrack（MODE_STATIC）。
     *
     * 波形設計：
     *   - 前 5ms  線性淡入（attack），避免爆音
     *   - 中 50ms 衰減（decay），模擬打擊音的 envelope
     *   - 後段  靜音，總長 100ms
     *
     * @param freqHz  基頻（Hz）
     * @param peakAmp 峰值振幅（0.0 ~ 1.0）
     */
    private fun buildAudioTrack(freqHz: Double, peakAmp: Float): AudioTrack {
        val durationMs = 100                          // 每個 click 的總時長（毫秒）
        val numSamples = sampleRate * durationMs / 1000  // = 4410 個取樣點
        val pcm = ShortArray(numSamples)

        val attackSamples = sampleRate * 5 / 1000    // 5ms attack
        val decaySamples  = sampleRate * 55 / 1000   // 55ms decay（到靜音）

        for (i in 0 until numSamples) {
            // 計算此取樣點的振幅包絡
            val envelope = when {
                i < attackSamples -> {
                    // Attack：線性從 0 升到 peakAmp
                    peakAmp * i.toFloat() / attackSamples
                }
                i < attackSamples + decaySamples -> {
                    // Decay：線性從 peakAmp 降到 0
                    val decayProgress = (i - attackSamples).toFloat() / decaySamples
                    peakAmp * (1.0f - decayProgress)
                }
                else -> 0.0f  // 靜音段
            }

            // 正弦波取樣
            val sinValue = sin(2.0 * PI * freqHz * i / sampleRate).toFloat()
            pcm[i] = (sinValue * envelope * Short.MAX_VALUE).toInt().toShort()
        }

        // 計算 MODE_STATIC 需要的 buffer size
        val bufferSize = AudioTrack.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_OUT_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        ).coerceAtLeast(numSamples * 2) // 每個 Short = 2 bytes

        val track = AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setSampleRate(sampleRate)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                    .build()
            )
            .setBufferSizeInBytes(bufferSize)
            .setTransferMode(AudioTrack.MODE_STATIC)
            .build()

        // 將 PCM 資料預先寫入 buffer（MODE_STATIC 只需寫一次）
        track.write(pcm, 0, numSamples)

        return track
    }

    /** 安全釋放 AudioTrack */
    private fun releaseTrack(track: AudioTrack) {
        try {
            track.stop()
            track.release()
        } catch (_: Exception) {}
    }
}
