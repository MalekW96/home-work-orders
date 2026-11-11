package com.malekw96.homeworkorders

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import org.json.JSONArray

/**
 * Follow-up reminders. The page sends the full list each time its tasks change
 * (`AndroidBridge.setReminders`); this replaces whatever was scheduled before.
 * Each item is {key, at (epoch ms), title, body}. A key is notified only once.
 */
object Reminders {
    private const val PREFS = "reminders"
    private const val KEY_LIST = "list"
    private const val KEY_DONE = "done"
    private const val CHANNEL = "followups"

    private fun prefs(ctx: Context) = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun ensureChannel(ctx: Context) {
        if (Build.VERSION.SDK_INT >= 26) {
            val nm = ctx.getSystemService(NotificationManager::class.java)
            if (nm.getNotificationChannel(CHANNEL) == null) {
                val ch = NotificationChannel(CHANNEL, "Follow-ups", NotificationManager.IMPORTANCE_HIGH)
                ch.description = "High-priority corrective tasks that have been waiting for further action"
                nm.createNotificationChannel(ch)
            }
        }
    }

    private fun pending(ctx: Context, key: String, title: String, body: String): PendingIntent {
        val intent = Intent(ctx, ReminderReceiver::class.java)
            .setAction("reminder:$key")
            .putExtra("key", key)
            .putExtra("title", title)
            .putExtra("body", body)
        return PendingIntent.getBroadcast(
            ctx, key.hashCode(), intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
    }

    fun schedule(ctx: Context, json: String) {
        val p = prefs(ctx)
        val alarms = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        try {
            val old = JSONArray(p.getString(KEY_LIST, "[]") ?: "[]")
            for (i in 0 until old.length()) {
                val o = old.optJSONObject(i) ?: continue
                alarms.cancel(pending(ctx, o.optString("key"), "", ""))
            }
        } catch (_: Exception) { }
        p.edit().putString(KEY_LIST, json).apply()
        arm(ctx, json)
    }

    fun rescheduleSaved(ctx: Context) {
        arm(ctx, prefs(ctx).getString(KEY_LIST, "[]") ?: "[]")
    }

    private fun arm(ctx: Context, json: String) {
        val arr = try { JSONArray(json) } catch (_: Exception) { return }
        val done = prefs(ctx).getStringSet(KEY_DONE, emptySet()) ?: emptySet()
        val alarms = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val now = System.currentTimeMillis()
        for (i in 0 until arr.length()) {
            val o = arr.optJSONObject(i) ?: continue
            val key = o.optString("key")
            if (key.isEmpty() || done.contains(key)) continue
            val title = o.optString("title")
            val body = o.optString("body")
            val at = o.optLong("at")
            if (at <= now) {
                fire(ctx, key, title, body)
            } else {
                alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending(ctx, key, title, body))
            }
        }
    }

    fun fire(ctx: Context, key: String, title: String, body: String) {
        val p = prefs(ctx)
        val done = (p.getStringSet(KEY_DONE, emptySet()) ?: emptySet()).toMutableSet()
        if (done.contains(key)) return
        val allowed = Build.VERSION.SDK_INT < 33 ||
            ContextCompat.checkSelfPermission(ctx, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
        if (!allowed) return
        ensureChannel(ctx)
        val open = PendingIntent.getActivity(
            ctx, 0,
            Intent(ctx, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val n = NotificationCompat.Builder(ctx, CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_bang)
            .setContentTitle("! $title")
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(open)
            .build()
        try {
            NotificationManagerCompat.from(ctx).notify(key.hashCode(), n)
        } catch (_: SecurityException) {
            return
        }
        done.add(key)
        p.edit().putStringSet(KEY_DONE, done).apply()
    }
}

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val key = intent.getStringExtra("key") ?: return
        Reminders.fire(context, key, intent.getStringExtra("title") ?: "Follow-up needed", intent.getStringExtra("body") ?: "")
    }
}

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Reminders.rescheduleSaved(context)
    }
}
