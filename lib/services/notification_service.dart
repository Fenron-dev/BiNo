// Datei: lib/services/notification_service.dart
//
// ZWECK: Verwaltet lokale Push-Benachrichtigungen (Phase 6).
//        Drei Aufgaben:
//          1. Erinnerungs-Alarm für einzelne Einträge (exakt, einmalig)
//          2. Wöchentlicher Rückblick (sonntags 18:00, wiederkehrend)
//          3. Berechtigungs-Request für Android 13+
// ABHÄNGIGKEITEN: flutter_local_notifications, timezone, flutter_timezone.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Kanal-IDs
  static const _kReminderChannelId = 'bino_reminders';
  static const _kWeeklyChannelId = 'bino_weekly';

  // Feste ID für die wöchentliche Benachrichtigung
  static const _kWeeklyId = 999999;

  // ── Initialisierung ──────────────────────────────────────────────────────

  /// Muss einmalig beim App-Start aufgerufen werden (vor dem ersten Frame).
  static Future<void> initialize() async {
    if (_initialized) return;

    // IANA-Zeitzonen-Daten laden (benötigt für zonedSchedule).
    tz_data.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    // Kanäle anlegen (idempotent auf Android).
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _kReminderChannelId,
        'Erinnerungen',
        description: 'Erinnerungen für einzelne Einträge',
        importance: Importance.high,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _kWeeklyChannelId,
        'Wöchentlicher Rückblick',
        description: 'Sonntägliche Zusammenfassung',
        importance: Importance.defaultImportance,
      ),
    );

    _initialized = true;
  }

  // ── Berechtigungen ───────────────────────────────────────────────────────

  /// Fragt POST_NOTIFICATIONS-Berechtigung an (Android 13+).
  /// Gibt true zurück wenn gewährt oder nicht benötigt (< API 33).
  static Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? true;
  }

  /// Prüft ob exakte Alarme erlaubt sind (Android 12+).
  static Future<bool> canScheduleExact() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    return await android?.canScheduleExactNotifications() ?? true;
  }

  // ── Erinnerungen ─────────────────────────────────────────────────────────

  /// Plant eine Erinnerung für einen Eintrag.
  ///
  /// [entryId] wird auf eine deterministische Notification-ID gemappt,
  /// damit ein späterer Aufruf die bestehende Benachrichtigung ersetzt.
  static Future<void> scheduleReminder({
    required String entryId,
    required String body,
    required DateTime scheduledAt,
  }) async {
    final id = _idForEntry(entryId);
    final scheduled = tz.TZDateTime.from(scheduledAt.toUtc(), tz.UTC);

    await _plugin.zonedSchedule(
      id,
      'BiNo – Erinnerung',
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _kReminderChannelId,
          'Erinnerungen',
          channelDescription: 'Erinnerungen für einzelne Einträge',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      // Pflichtparameter für iOS (nicht genutzt auf Android).
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Bricht die Erinnerung für einen Eintrag ab (z. B. nach Löschen oder Ändern).
  static Future<void> cancelReminder(String entryId) async {
    await _plugin.cancel(_idForEntry(entryId));
  }

  // ── Wöchentlicher Rückblick ───────────────────────────────────────────────

  /// Plant eine wiederkehrende Sonntagsbenachrichtigung um 18:00 Uhr.
  /// Bereits vorhandene Planung wird überschrieben (gleiche ID).
  static Future<void> scheduleWeeklyDigest() async {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, 18);

    // Nächsten Sonntag um 18:00 berechnen (weekday 7 = Sonntag).
    while (next.weekday != DateTime.sunday || next.isBefore(now)) {
      next = next.add(const Duration(hours: 24));
    }

    await _plugin.zonedSchedule(
      _kWeeklyId,
      'BiNo – Wöchentlicher Rückblick',
      'Was hast du diese Woche festgehalten?',
      next,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _kWeeklyChannelId,
          'Wöchentlicher Rückblick',
          channelDescription: 'Sonntägliche Zusammenfassung',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      // inexact: kein SCHEDULE_EXACT_ALARM nötig, Gerät darf verschieben.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      // Pflichtparameter für iOS (nicht genutzt auf Android).
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
    );
  }

  /// Deaktiviert den wöchentlichen Rückblick.
  static Future<void> cancelWeeklyDigest() async {
    await _plugin.cancel(_kWeeklyId);
  }

  // ── Hilfsfunktionen ──────────────────────────────────────────────────────

  // UUID → stabiler int-ID (positiv, < 2^31).
  static int _idForEntry(String entryId) =>
      entryId.hashCode.abs() % 2000000000;
}
