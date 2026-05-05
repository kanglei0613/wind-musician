package com.kanglei.muklang

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat

/**
 * NotificationHelper
 *
 * 負責建立通知頻道（Android 8+）及組裝前景服務通知。
 * 前景服務必須持有一個可見通知，才能在背景持續運行。
 */
object NotificationHelper {

    /** 通知頻道 ID（與 createChannel 保持一致） */
    const val CHANNEL_ID = "metronome_channel"

    /** 前景服務通知 ID（必須非零） */
    const val NOTIFICATION_ID = 1001

    /**
     * 建立通知頻道（Android 8.0 / API 26 以上必須在發通知前建立）。
     * 此方法可安全重複呼叫——若頻道已存在，系統會忽略。
     *
     * @param context 應用程式 Context
     */
    fun createChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                context.getString(R.string.metronome_channel_name),
                NotificationManager.IMPORTANCE_LOW  // LOW：靜音但可見，不打擾用戶
            ).apply {
                description = context.getString(R.string.metronome_channel_desc)
                // 關閉震動與聲音，避免通知本身的聲音干擾節拍器
                enableVibration(false)
                setSound(null, null)
            }

            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE)
                    as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    /**
     * 組裝前景服務通知。
     *
     * @param context  應用程式 Context
     * @param bpm      目前 BPM，顯示於通知內文
     * @param timeSig  拍號字串（例如 "4/4"），顯示於通知副標題
     * @return         已組裝的 Notification 物件
     */
    fun buildNotification(context: Context, bpm: Int, timeSig: String): Notification {
        // 點擊通知時回到 App 主畫面
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            // Android 12+ 要求 FLAG_IMMUTABLE 或 FLAG_MUTABLE
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_metronome_notification)
            .setContentTitle(context.getString(R.string.metronome_notification_title))
            .setContentText("$bpm BPM · $timeSig")
            .setOngoing(true)           // 持續通知，使用者無法直接滑除
            .setSilent(true)            // 不播放通知音效
            .setContentIntent(pendingIntent)
            // 通知類別設為傳輸（媒體播放），影響 Android 的通知分組邏輯
            .setCategory(NotificationCompat.CATEGORY_TRANSPORT)
            .build()
    }

    /**
     * 更新已顯示的通知內容（BPM 或拍號改變時呼叫）。
     *
     * @param context  應用程式 Context
     * @param bpm      新 BPM
     * @param timeSig  新拍號字串
     */
    fun updateNotification(context: Context, bpm: Int, timeSig: String) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE)
                as NotificationManager
        manager.notify(NOTIFICATION_ID, buildNotification(context, bpm, timeSig))
    }
}
