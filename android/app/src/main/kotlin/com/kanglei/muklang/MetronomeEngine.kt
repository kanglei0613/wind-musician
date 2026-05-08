package com.kanglei.muklang

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.os.Handler
import android.os.HandlerThread
import android.os.Process
import android.os.SystemClock
import kotlin.math.PI
import kotlin.math.exp
import kotlin.math.roundToInt
import kotlin.math.sin

// ── 音色類型 ─────────────────────────────────────────────────────────────────
enum class SoundType { SINE, WOODBLOCK, STICK_CLICK, SNARE }

/**
 * MetronomeEngine
 *
 * 節拍器核心引擎，負責：
 *   1. 在高優先級 HandlerThread 上排程每一拍
 *   2. 以 AudioTrack（MODE_STATIC + PCM 短波形）播放打擊音
 *   3. 使用 SystemClock.elapsedRealtime() 做絕對時間補償，消除累積漂移
 *   4. 支援 4 種音色 × 5 個音高變體（強拍/弱拍各一組 track）
 *
 * @param onBeat  每拍回呼（在 audioThread 執行，由呼叫方負責切換執行緒）
 */
class MetronomeEngine(private val onBeat: () -> Unit) {

    // ── 音高變體頻率表（強拍 Hz, 弱拍 Hz）──────────────────────────────────
    // variant 1 = 最低，5 = 最高；弱拍 = 強拍 × 0.75
    private val pitchVariantFreqs = mapOf(
        1 to Pair(500.0,  375.0),
        2 to Pair(700.0,  525.0),
        3 to Pair(1000.0, 750.0),   // 預設
        4 to Pair(1400.0, 1050.0),
        5 to Pair(2000.0, 1500.0),
    )

    // ── 音訊執行緒 ─────────────────────────────────────────────────────────
    private val audioThread = HandlerThread(
        "MetronomeAudioThread",
        Process.THREAD_PRIORITY_AUDIO
    ).also { it.start() }

    private val handler = Handler(audioThread.looper)

    // ── 狀態 ──────────────────────────────────────────────────────────────
    @Volatile private var isRunning = false
    @Volatile private var bpm: Int = 120
    @Volatile private var numerator: Int = 4
    @Volatile private var denominator: Int = 4
    @Volatile private var currentSoundType: SoundType = SoundType.SINE
    @Volatile private var currentPitchVariant: Int = 3   // 1~5

    private var startElapsedMs: Long = 0L
    private var scheduledBeatIndex: Int = 0

    // ── AudioTrack（可在運行中熱替換）────────────────────────────────────
    private val sampleRate = 44100

    /** 強拍 / 弱拍 track（在 audioThread 上存取與替換）*/
    private var strongTrack: AudioTrack = buildSoundTrack(isStrong = true)
    private var weakTrack: AudioTrack   = buildSoundTrack(isStrong = false)

    // ── 公開介面 ──────────────────────────────────────────────────────────

    fun start(initialBpm: Int, initialNumerator: Int, initialDenominator: Int) {
        stop()
        bpm         = initialBpm
        numerator   = initialNumerator
        denominator = initialDenominator
        isRunning   = true
        startElapsedMs    = SystemClock.elapsedRealtime()
        scheduledBeatIndex = 0
        handler.post { fireBeatAndScheduleNext() }
    }

    fun stop() {
        isRunning = false
        handler.removeCallbacksAndMessages(null)
    }

    fun updateBpm(newBpm: Int) {
        bpm = newBpm
        if (isRunning) resetTiming()
    }

    fun updateTimeSig(newNumerator: Int, newDenominator: Int) {
        numerator   = newNumerator
        denominator = newDenominator
        if (isRunning) resetTiming()
    }

    /**
     * 切換音色（運行中也可呼叫，在 audioThread 熱替換 AudioTrack）。
     */
    fun setSoundType(newType: SoundType) {
        currentSoundType = newType
        rebuildTracks()
    }

    /**
     * 切換音高變體 1~5（運行中也可呼叫）。
     */
    fun setPitchVariant(variant: Int) {
        currentPitchVariant = variant.coerceIn(1, 5)
        rebuildTracks()
    }

    fun release() {
        stop()
        audioThread.quit()
        releaseTrack(strongTrack)
        releaseTrack(weakTrack)
    }

    // ── 內部排程 ──────────────────────────────────────────────────────────

    private fun resetTiming() {
        handler.removeCallbacksAndMessages(null)
        startElapsedMs    = SystemClock.elapsedRealtime()
        scheduledBeatIndex = 0
        handler.post { fireBeatAndScheduleNext() }
    }

    /**
     * 在 audioThread 上重建 strongTrack / weakTrack，
     * 先建新的再釋放舊的，確保不中斷播放中的拍點。
     */
    private fun rebuildTracks() {
        handler.post {
            val oldStrong = strongTrack
            val oldWeak   = weakTrack
            strongTrack = buildSoundTrack(isStrong = true)
            weakTrack   = buildSoundTrack(isStrong = false)
            releaseTrack(oldStrong)
            releaseTrack(oldWeak)
        }
    }

    private fun fireBeatAndScheduleNext() {
        if (!isRunning) return

        val beatInMeasure = scheduledBeatIndex % numerator
        val isDownBeat    = beatInMeasure == 0

        playClick(if (isDownBeat) strongTrack else weakTrack)
        onBeat()

        val intervalMs = (60_000.0 / bpm) * (4.0 / denominator)
        scheduledBeatIndex++
        val targetMs  = (scheduledBeatIndex * intervalMs).roundToInt().toLong()
        val elapsedMs = SystemClock.elapsedRealtime() - startElapsedMs
        val delayMs   = (targetMs - elapsedMs).coerceIn(0L, (intervalMs * 2).toLong())

        handler.postDelayed({ fireBeatAndScheduleNext() }, delayMs)
    }

    private fun playClick(track: AudioTrack) {
        try {
            track.stop()
            track.reloadStaticData()
            track.play()
        } catch (_: Exception) { }
    }

    // ── 音色合成（依 currentSoundType / currentPitchVariant 決定） ─────────

    /**
     * 根據目前 soundType 與 pitchVariant 建立一個 AudioTrack。
     *
     * @param isStrong  true = 強拍頻率，false = 弱拍頻率
     */
    private fun buildSoundTrack(isStrong: Boolean): AudioTrack {
        val (strongFreq, weakFreq) =
            pitchVariantFreqs[currentPitchVariant] ?: Pair(1000.0, 750.0)
        val freq = if (isStrong) strongFreq else weakFreq
        val amp  = if (isStrong) 1.0f else 0.75f

        return when (currentSoundType) {
            SoundType.SINE       -> buildSineTrack(freq, amp)
            SoundType.WOODBLOCK  -> buildWoodblockTrack(freq)
            SoundType.STICK_CLICK-> buildStickClickTrack(freq)
            SoundType.SNARE      -> buildSnareTrack(freq)
        }
    }

    // ── 正弦波（原始設計）────────────────────────────────────────────────
    /**
     * 波形：正弦，Attack 5ms 淡入 → Decay 55ms 線性衰減 → 靜音，總長 100ms
     */
    private fun buildSineTrack(freqHz: Double, peakAmp: Float): AudioTrack {
        val durationMs    = 100
        val numSamples    = sampleRate * durationMs / 1000
        val attackSamples = sampleRate * 5  / 1000
        val decaySamples  = sampleRate * 55 / 1000
        val pcm = ShortArray(numSamples)

        for (i in 0 until numSamples) {
            val envelope = when {
                i < attackSamples ->
                    peakAmp * i.toFloat() / attackSamples
                i < attackSamples + decaySamples ->
                    peakAmp * (1f - (i - attackSamples).toFloat() / decaySamples)
                else -> 0f
            }
            pcm[i] = (sin(2.0 * PI * freqHz * i / sampleRate) * envelope * Short.MAX_VALUE)
                .toInt().toShort()
        }
        return createAudioTrack(pcm)
    }

    // ── 木魚（Woodblock）─────────────────────────────────────────────────
    /**
     * 波形：高頻正弦 + 指數衰減，總長 80ms，前 30ms 快速衰減。
     *
     * 各音高變體頻率（強拍/弱拍）：
     *   1: 500/375 Hz  2: 700/525 Hz  3: 1000/750 Hz（預設）
     *   4: 1400/1050 Hz  5: 2000/1500 Hz
     */
    private fun buildWoodblockTrack(freqHz: Double): AudioTrack {
        val durationMs   = 80
        val numSamples   = sampleRate * durationMs / 1000
        val decaySamples = sampleRate * 30 / 1000   // 30ms 快速衰減
        val peakAmp      = 1.0f
        val pcm = ShortArray(numSamples)

        for (i in 0 until numSamples) {
            val envelope = when {
                i < decaySamples -> {
                    // 指數衰減：e^(-5t)，t = i/decaySamples
                    peakAmp * exp(-5.0 * i.toDouble() / decaySamples).toFloat()
                }
                else -> 0f
            }
            pcm[i] = (sin(2.0 * PI * freqHz * i / sampleRate) * envelope * Short.MAX_VALUE)
                .toInt().toShort()
        }
        return createAudioTrack(pcm)
    }

    // ── 鼓棒敲擊（Stick Click）────────────────────────────────────────────
    /**
     * 波形：超短高頻 click，15ms 極快指數衰減，總長 50ms。
     *
     * 各音高變體頻率（強拍/弱拍）：
     *   1: 500/375 Hz  2: 700/525 Hz  3: 1000/750 Hz
     *   4: 1400/1050 Hz  5: 2000/1500 Hz
     */
    private fun buildStickClickTrack(freqHz: Double): AudioTrack {
        val durationMs   = 50
        val numSamples   = sampleRate * durationMs / 1000
        val decaySamples = sampleRate * 15 / 1000   // 15ms 極短衰減
        val peakAmp      = 1.0f
        val pcm = ShortArray(numSamples)

        for (i in 0 until numSamples) {
            val envelope = when {
                i < decaySamples -> {
                    // 更陡的指數衰減 e^(-8t)
                    peakAmp * exp(-8.0 * i.toDouble() / decaySamples).toFloat()
                }
                else -> 0f
            }
            pcm[i] = (sin(2.0 * PI * freqHz * i / sampleRate) * envelope * Short.MAX_VALUE)
                .toInt().toShort()
        }
        return createAudioTrack(pcm)
    }

    // ── 小鼓（Snare）─────────────────────────────────────────────────────
    /**
     * 波形：低頻正弦（60%）+ 白噪音（40%），60ms 線性衰減，總長 100ms。
     *
     * 各音高變體頻率（強拍/弱拍）：
     *   1: 500/375 Hz  2: 700/525 Hz  3: 1000/750 Hz
     *   4: 1400/1050 Hz  5: 2000/1500 Hz
     */
    private fun buildSnareTrack(freqHz: Double): AudioTrack {
        val durationMs   = 100
        val numSamples   = sampleRate * durationMs / 1000
        val decaySamples = sampleRate * 60 / 1000   // 60ms 線性衰減
        val peakAmp      = 1.0f
        val noiseRatio   = 0.4f
        val random       = java.util.Random(42L)     // 固定 seed，確保每次相同
        val pcm = ShortArray(numSamples)

        for (i in 0 until numSamples) {
            val envelope = when {
                i < decaySamples ->
                    peakAmp * (1f - i.toFloat() / decaySamples)
                else -> 0f
            }
            val sinValue   = sin(2.0 * PI * freqHz * i / sampleRate).toFloat()
            val noiseValue = random.nextFloat() * 2f - 1f   // [-1, 1]
            val mixed      = sinValue * (1f - noiseRatio) + noiseValue * noiseRatio
            pcm[i] = (mixed * envelope * Short.MAX_VALUE).toInt().toShort()
        }
        return createAudioTrack(pcm)
    }

    // ── AudioTrack 建立工具 ────────────────────────────────────────────────

    /**
     * 將 PCM 資料包裝成 MODE_STATIC AudioTrack。
     * 波形預先寫入，play() 呼叫延遲極低。
     */
    private fun createAudioTrack(pcm: ShortArray): AudioTrack {
        val bufferSize = AudioTrack.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_OUT_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        ).coerceAtLeast(pcm.size * 2)

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

        track.write(pcm, 0, pcm.size)
        return track
    }

    private fun releaseTrack(track: AudioTrack) {
        try {
            track.stop()
            track.release()
        } catch (_: Exception) { }
    }
}
