package com.example.widget_class

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Shader
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import kotlin.math.roundToInt

class ActivitiesWidgetProvider : HomeWidgetProvider() {
    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetRefreshScheduler.schedule(context)
        WidgetBackgroundSync.refreshAsync(context)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        WidgetRefreshScheduler.schedule(context)
        appWidgetIds.forEach { widgetId ->
            appWidgetManager.updateAppWidget(widgetId, buildRemoteViews(context, widgetData))
        }
        WidgetBackgroundSync.refreshAsync(context)
    }

    companion object {
        fun updateAll(context: Context, widgetData: SharedPreferences) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val ids = appWidgetManager.getAppWidgetIds(
                ComponentName(context, ActivitiesWidgetProvider::class.java),
            )
            ids.forEach { widgetId ->
                appWidgetManager.updateAppWidget(widgetId, buildRemoteViews(context, widgetData))
            }
        }

        private fun buildRemoteViews(
            context: Context,
            widgetData: SharedPreferences,
        ): RemoteViews {
            val workTitle = widgetData.getString("work_title", "Sem trabalhos")
                ?: "Sem trabalhos"
            val workSubject = widgetData.getString("work_subject", "Agenda livre")
                ?: "Agenda livre"
            val workDate = widgetData.getString("work_date", "--") ?: "--"
            val evalTitle = widgetData.getString("eval_title", "Sem avaliacoes")
                ?: "Sem avaliacoes"
            val evalSubject = widgetData.getString("eval_subject", "Agenda livre")
                ?: "Agenda livre"
            val evalDate = widgetData.getString("eval_date", "--") ?: "--"
            val workColor = parseColor(widgetData.getString("work_color_hex", "#1B9AAA"))
            val evalColor = parseColor(widgetData.getString("eval_color_hex", "#5B7CFA"))

            return RemoteViews(context.packageName, R.layout.activities_widget).apply {
                setImageViewBitmap(
                    R.id.activities_widget_background,
                    createBackground(workColor, evalColor),
                )
                setTextViewText(R.id.widget_work_title, workTitle)
                setTextViewText(R.id.widget_work_subject, workSubject)
                setTextViewText(R.id.widget_work_date, workDate)
                setTextViewText(R.id.widget_eval_title, evalTitle)
                setTextViewText(R.id.widget_eval_subject, evalSubject)
                setTextViewText(R.id.widget_eval_date, evalDate)

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                )
                setOnClickPendingIntent(R.id.activities_widget_root, pendingIntent)
            }
        }

        private fun parseColor(hex: String?): Int {
            return try {
                Color.parseColor(hex ?: "#1B9AAA")
            } catch (_: IllegalArgumentException) {
                Color.parseColor("#1B9AAA")
            }
        }

        private fun createBackground(startColor: Int, endColor: Int): Bitmap {
            val width = 980
            val height = 430
            val radius = 58f
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = LinearGradient(
                    0f,
                    0f,
                    width.toFloat(),
                    height.toFloat(),
                    blendWithBlack(blendWithWhite(startColor, 0.08f), 0.12f),
                    blendWithBlack(blendWithWhite(endColor, 0.10f), 0.10f),
                    Shader.TileMode.CLAMP,
                )
            }
            canvas.drawRoundRect(
                RectF(0f, 0f, width.toFloat(), height.toFloat()),
                radius,
                radius,
                paint,
            )
            return bitmap
        }

        private fun blendWithWhite(color: Int, amount: Float): Int {
            val inverse = 1f - amount
            val red = (Color.red(color) * inverse + 255 * amount).roundToInt()
            val green = (Color.green(color) * inverse + 255 * amount).roundToInt()
            val blue = (Color.blue(color) * inverse + 255 * amount).roundToInt()
            return Color.rgb(red, green, blue)
        }

        private fun blendWithBlack(color: Int, amount: Float): Int {
            val inverse = 1f - amount
            val red = (Color.red(color) * inverse).roundToInt()
            val green = (Color.green(color) * inverse).roundToInt()
            val blue = (Color.blue(color) * inverse).roundToInt()
            return Color.rgb(red, green, blue)
        }
    }
}
