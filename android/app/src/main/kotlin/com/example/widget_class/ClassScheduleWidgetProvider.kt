package com.example.widget_class

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class ClassScheduleWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val disciplina = widgetData.getString(
                "current_disciplina",
                "Sem aula restante",
            ) ?: "Sem aula restante"
            val professor = widgetData.getString(
                "current_professor",
                "Nenhum professor",
            ) ?: "Nenhum professor"
            val sala = widgetData.getString("current_sala", "Sem sala") ?: "Sem sala"

            val views = RemoteViews(context.packageName, R.layout.class_schedule_widget).apply {
                setTextViewText(R.id.widget_disciplina, disciplina)
                setTextViewText(R.id.widget_professor, professor)
                setTextViewText(R.id.widget_sala, sala)

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                )
                setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
