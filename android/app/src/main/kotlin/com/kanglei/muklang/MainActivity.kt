package com.kanglei.muklang

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity
 *
 * Flutter 宿主 Activity，負責：
 *   1. 註冊 Platform Channel（metronome + audio_focus）
 *   2. 管理 MetronomeService 的 bind/unbind 生命週期
 *   3. 將節拍事件（onBeat）從 Service 的 audioThread 轉發至 Flutter main isolate
 *
 * Platform Channel 設計：
 *   ① com.kanglei.muklang/metronome
 *      Flutter → Native：start, stop, updateBpm, updateTimeSig
 *      Native → Flutter：invokeMethod("onBeat")
 *
 *   ② com.kanglei.muklang/audio_focus
 *      Native → Flutter：invokeMethod("onFocusChange", focusChangeCode)
 *      （Flutter 用此事件更新 UI 狀態，例如顯示「音訊焦點被搶走」提示）
 */
class MainActivity : FlutterActivity() {

    // ── Platform Channel 名稱常數 ─────────────────────────────────────────
    companion object {
        const val METRONOME_CHANNEL = "com.kanglei.muklang/metronome"
        const val AUDIO_FOCUS_CHANNEL = "com.kanglei.muklang/audio_focus"
        /** 音叉音訊控制：Flutter 呼叫 requestFocus / releaseFocus */
        const val PITCH_FORK_CHANNEL = "com.kanglei.muklang/pitch_fork"
    }

    // ── Channel 物件（在 configureFlutterEngine 建立後持有） ───────────────
    private var metronomeChannel: MethodChannel? = null
    private var audioFocusChannel: MethodChannel? = null

    // ── 音叉音訊焦點 ──────────────────────────────────────────────────────
    /** 音叉專用 AudioFocus 處理器（與節拍器分開管理） */
    private var pitchForkAudioFocusHandler: AudioFocusHandler? = null
    /** 音叉播放時持有的 PARTIAL_WAKE_LOCK，防止 CPU 休眠導致音訊中斷 */
    private var pitchForkWakeLock: PowerManager.WakeLock? = null

    // ── MetronomeService 連線 ─────────────────────────────────────────────
    private var metronomeService: MetronomeService? = null
    private var isBound = false

    /**
     * 待執行的 startMetronome 參數：
     * 若 "start" 指令在 onServiceConnected 之前到達，先暫存這裡，
     * 等連線成功後再執行，避免指令遺失。
     */
    private data class PendingStart(val bpm: Int, val numerator: Int, val denominator: Int)
    private var pendingStart: PendingStart? = null

    /** 主執行緒 Handler（將 audioThread 的事件轉回 main looper） */
    private val mainHandler = Handler(Looper.getMainLooper())

    /** ServiceConnection 回呼：bind 成功後取得 Service 實例並設置 beat 回呼 */
    private val serviceConnection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName?, binder: IBinder?) {
            val b = binder as? MetronomeService.MetronomeBinder ?: return
            metronomeService = b.getService()
            isBound = true

            // ① Beat 回呼：Service 的 audioThread → 切回 main looper → 通知 Flutter
            metronomeService?.onBeatCallback = {
                mainHandler.post {
                    // invokeMethod 必須在 main thread 執行
                    metronomeChannel?.invokeMethod("onBeat", null)
                }
            }

            // ② AudioFocus 回呼：焦點變化 → 切回 main looper → 通知 Flutter audio_focus channel
            metronomeService?.onAudioFocusChangeCallback = { focusChange ->
                mainHandler.post {
                    audioFocusChannel?.invokeMethod("onFocusChange", focusChange)
                }
            }

            // ③ 執行暫存的 start 指令（若 "start" 在 bind 完成前到達）
            pendingStart?.let { p ->
                pendingStart = null
                metronomeService?.startMetronome(p.bpm, p.numerator, p.denominator)
            }
        }

        override fun onServiceDisconnected(name: ComponentName?) {
            metronomeService = null
            isBound = false
        }
    }

    // ── FlutterEngine 設定 ────────────────────────────────────────────────

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // ① 節拍器 Channel
        metronomeChannel = MethodChannel(messenger, METRONOME_CHANNEL).also { ch ->
            ch.setMethodCallHandler { call, result ->
                handleMetronomeCall(call.method, call.arguments, result)
            }
        }

        // ② AudioFocus Channel（Native → Flutter 單向，此處設 handler 供未來雙向擴充）
        audioFocusChannel = MethodChannel(messenger, AUDIO_FOCUS_CHANNEL).also { ch ->
            ch.setMethodCallHandler { _, result ->
                // 目前無 Flutter → Native 的指令，直接回傳 notImplemented
                result.notImplemented()
            }
        }

        // ③ 音叉音訊控制 Channel
        //    Flutter 在音叉開始/停止播放時呼叫 requestFocus / releaseFocus
        MethodChannel(messenger, PITCH_FORK_CHANNEL).also { ch ->
            ch.setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestFocus" -> {
                        acquirePitchForkAudio()
                        result.success(null)
                    }
                    "releaseFocus" -> {
                        releasePitchForkAudio()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    // ── Activity 生命週期 ─────────────────────────────────────────────────

    override fun onDestroy() {
        // Activity 銷毀時確保音叉資源全部釋放，防止 WakeLock 洩漏
        releasePitchForkAudio()
        super.onDestroy()
    }

    override fun onStart() {
        super.onStart()
        // Activity 進入前景時嘗試 bind Service（Service 可能尚未啟動，bindService 允許此情況）
        val intent = Intent(this, MetronomeService::class.java)
        bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)
    }

    override fun onStop() {
        super.onStop()
        if (isBound) {
            unbindService(serviceConnection)
            isBound = false
        }
    }

    // ── Metronome Channel 指令處理 ────────────────────────────────────────

    /**
     * 處理來自 Flutter 的節拍器控制指令。
     *
     * 指令列表：
     *   start        args: {"bpm": Int, "numerator": Int, "denominator": Int}
     *   stop         args: null
     *   updateBpm    args: {"bpm": Int}
     *   updateTimeSig args: {"numerator": Int, "denominator": Int}
     */
    private fun handleMetronomeCall(
        method: String,
        arguments: Any?,
        result: MethodChannel.Result
    ) {
        @Suppress("UNCHECKED_CAST")
        val args = arguments as? Map<String, Any> ?: emptyMap()

        when (method) {
            "start" -> {
                val bpm         = (args["bpm"]         as? Int) ?: 120
                val numerator   = (args["numerator"]   as? Int) ?: 4
                val denominator = (args["denominator"] as? Int) ?: 4

                // 啟動前景服務（Android 8+ 需用 startForegroundService）
                val intent = Intent(this, MetronomeService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    startForegroundService(intent)
                } else {
                    startService(intent)
                }

                if (isBound) {
                    // 已 bind：直接呼叫
                    metronomeService?.startMetronome(bpm, numerator, denominator)
                } else {
                    // 尚未 bind：暫存參數，等 onServiceConnected 後執行
                    pendingStart = PendingStart(bpm, numerator, denominator)
                    bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE)
                }

                result.success(null)
            }

            "stop" -> {
                metronomeService?.stopMetronome()
                result.success(null)
            }

            "updateBpm" -> {
                val bpm = (args["bpm"] as? Int) ?: return result.error(
                    "INVALID_ARG", "updateBpm 缺少 bpm 參數", null
                )
                metronomeService?.updateBpm(bpm)
                result.success(null)
            }

            "updateTimeSig" -> {
                val numerator   = (args["numerator"]   as? Int) ?: return result.error(
                    "INVALID_ARG", "updateTimeSig 缺少參數", null
                )
                val denominator = (args["denominator"] as? Int) ?: return result.error(
                    "INVALID_ARG", "updateTimeSig 缺少參數", null
                )
                metronomeService?.updateTimeSig(numerator, denominator)
                result.success(null)
            }

            "setSoundType" -> {
                val sound = (args["sound"] as? String) ?: "SINE"
                metronomeService?.setSoundType(sound)
                result.success(null)
            }

            "setPitchVariant" -> {
                val variant = (args["variant"] as? Int) ?: 3
                metronomeService?.setPitchVariant(variant)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    // ── 音叉音訊焦點 / WakeLock 輔助方法 ─────────────────────────────────

    /**
     * 音叉開始播放時呼叫：
     *   1. 請求 AudioFocus（通知其他 App 讓出音訊通道）
     *   2. 取得 PARTIAL_WAKE_LOCK（防止螢幕關閉後 CPU 休眠、SoLoud 音訊中斷）
     *
     * 可安全重複呼叫（已持有焦點/鎖定時為 no-op）。
     */
    private fun acquirePitchForkAudio() {
        // ① AudioFocus
        if (pitchForkAudioFocusHandler == null) {
            pitchForkAudioFocusHandler = AudioFocusHandler(this) { focusChange ->
                // 焦點變化轉發至 Flutter（例如來電時暫停 UI）
                mainHandler.post {
                    audioFocusChannel?.invokeMethod("onPitchForkFocusChange", focusChange)
                }
            }
        }
        pitchForkAudioFocusHandler?.requestFocus()

        // ② WakeLock（最長 30 分鐘，正常情況下由 releasePitchForkAudio 提前釋放）
        if (pitchForkWakeLock == null || pitchForkWakeLock?.isHeld == false) {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            pitchForkWakeLock = pm.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "WindMusician:PitchForkWakeLock"
            ).apply { acquire(30 * 60 * 1000L) }
        }
    }

    /**
     * 音叉停止播放時呼叫：釋放 AudioFocus 與 WakeLock。
     *
     * 可安全重複呼叫（未持有時為 no-op）。
     */
    private fun releasePitchForkAudio() {
        pitchForkAudioFocusHandler?.abandonFocus()
        pitchForkAudioFocusHandler = null

        pitchForkWakeLock?.let { if (it.isHeld) it.release() }
        pitchForkWakeLock = null
    }
}
