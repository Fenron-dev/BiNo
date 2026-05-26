package dev.fenron.bino_bit_notes

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * AppWidgetProvider für das BiNo Homescreen-Widget.
 *
 * Die Vorschau-Daten (letzter Eintrag) werden vom Flutter-Code via
 * home_widget-Package in SharedPreferences gespeichert (Dateiname
 * "HomeWidgetPreferences") und hier ausgelesen.
 *
 * Klick auf das Widget oder den "+ Notiz"-Button öffnet die App.
 * Der Capture-Intent übergibt OPEN_CAPTURE=true, damit MainActivity
 * die CaptureSheet direkt nach dem Start anzeigen kann.
 */
class BiNoWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (id in appWidgetIds) {
            updateWidget(context, appWidgetManager, id)
        }
    }

    companion object {
        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(
                "HomeWidgetPreferences",
                Context.MODE_PRIVATE
            )
            val lastBody = prefs.getString("widget_last_body", "Tippe auf ＋ Notiz um loszulegen")
                ?: "Tippe auf ＋ Notiz um loszulegen"
            val lastTimestamp = prefs.getString("widget_last_timestamp", "") ?: ""

            val views = RemoteViews(context.packageName, R.layout.bino_widget)
            views.setTextViewText(R.id.widget_preview, lastBody)
            views.setTextViewText(R.id.widget_timestamp, lastTimestamp)

            // Klick auf das gesamte Widget öffnet die App
            val openIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val openPending = PendingIntent.getActivity(
                context, 0, openIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, openPending)

            // Klick auf "+ Notiz" öffnet die App mit Capture-Flag
            val captureIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("OPEN_CAPTURE", true)
            }
            val capturePending = PendingIntent.getActivity(
                context, 1, captureIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_capture_btn, capturePending)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
