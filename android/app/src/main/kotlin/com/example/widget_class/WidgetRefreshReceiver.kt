package com.example.widget_class

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class WidgetRefreshReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action == Intent.ACTION_BOOT_COMPLETED) {
            WidgetRefreshScheduler.schedule(context)
        }

        val pendingResult = goAsync()
        Thread {
            try {
                WidgetBackgroundSync.sync(context.applicationContext)
            } catch (_: Exception) {
                // Sem rede ou Supabase indisponivel: o widget fica com o ultimo cache.
            } finally {
                pendingResult.finish()
            }
        }.start()
    }
}
