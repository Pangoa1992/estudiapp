package com.willy.estudiapp

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

class RachaWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val racha = prefs.getString("flutter.racha", "0") ?: "0"
        val habitos = prefs.getString("flutter.habitos_hoy", "Sin habitos hoy") ?: "Sin habitos hoy"

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.racha_widget)
            views.setTextViewText(R.id.tv_racha, racha)
            views.setTextViewText(R.id.tv_habitos, habitos)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
