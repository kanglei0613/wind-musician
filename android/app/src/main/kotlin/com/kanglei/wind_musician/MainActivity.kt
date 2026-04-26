package com.kanglei.wind_musician

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
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
 *   ① com.kanglei.wind_musician/metronome
 *      Flutter → Native：start, stop, updateBpm, updateTimeSig
 *      Native → Flutter：invokeMethod("onBeat")
 *
 *   ② com.kanglei.wind_musician/audio_focus
 *      Native → Flutter：invokeMethod("onFocusChange", focusChangeCode)
 *      （Flutter 用此事件更新 UI 狀態，例如顯示「音訊焦點被搶走」提示）
 */
class MainActivity : FlutterActivity() {

    // ── Platform Channel 名稱常數 ─────────────────────────────────────────
    companion object {
        const val METRONOME_CHANNEL = "com.kanglei.wind_musician/metronome"
        const val AUDIO_FOCUS_CHANNEL = "com.kanglei.wind_musician/audio_focus"
    }

    // ── Channel 物件（在 configureFlutterEngine 建立後持有） ───────────────
    private var metronomeChannel: MethodChannel? = null
    private var audioFocusChannel: MethodChannel? = null

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
    }

    // ── Activity 生命週期 ─────────────────────────────────────────────────

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

            else -> result.notImplemented()
        }
    }
}
