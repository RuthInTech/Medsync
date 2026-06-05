import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/medication.dart';

/// Schedules offline, on-time medication reminders.
///
/// Uses the OS-level scheduler via `flutter_local_notifications`, so alerts fire
/// at the prescribed time even with the app closed and no connectivity. The
/// service degrades gracefully: on platforms without plugin support (or when
/// initialization fails) it no-ops instead of crashing the app, so the rest of
/// Siyaphila keeps working.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _available = false;
  bool get isAvailable => _available;

  static const _channelId = 'siyaphila_doses';
  static const _channelName = 'Medication reminders';
  static const _channelDescription = 'On-time medication reminders';

  Future<void> init() async {
    try {
      // Timezone database must be ready before any zoned scheduling.
      await _configureTimeZone();

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const settings =
          InitializationSettings(android: android, iOS: ios, macOS: ios);
      await _plugin.initialize(settings: settings);

      // Explicitly create the Android channel so the very first reminder
      // (scheduled or immediate) is delivered with the right importance.
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
      ));

      _available = true;
    } catch (e) {
      // Web/desktop-without-support or a misconfigured host — stay silent.
      _available = false;
      debugPrint('NotificationService unavailable: $e');
    }
  }

  /// Resolve the device's IANA zone so wall-clock reminder times are correct.
  Future<void> _configureTimeZone() async {
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      // Fall back to matching the current UTC offset, then UTC, so scheduling
      // still works even if the platform can't name its zone.
      debugPrint('Timezone lookup failed ($e); using offset fallback.');
      _setLocationFromOffset();
    }
  }

  void _setLocationFromOffset() {
    final offset = DateTime.now().timeZoneOffset;
    for (final loc in tz.timeZoneDatabase.locations.values) {
      if (tz.TZDateTime.now(loc).timeZoneOffset == offset) {
        tz.setLocalLocation(loc);
        return;
      }
    }
    tz.setLocalLocation(tz.getLocation('UTC'));
  }

  /// Requests OS permission to post notifications (Android 13+ / iOS) and the
  /// exact-alarm permission so reminders fire on the minute.
  Future<void> requestPermissions() async {
    if (!_available) return;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('Permission request failed: $e');
    }
  }

  /// Shows an immediate behavioral nudge (used for the "test reminder").
  Future<void> showNow(String title, String body) async {
    if (!_available) return;
    try {
      await _plugin.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title,
        body: body,
        notificationDetails: _details(),
      );
    } catch (e) {
      debugPrint('showNow failed: $e');
    }
  }

  /// Schedules a daily, repeating reminder for every dose time of [med].
  ///
  /// Each schedule time gets a stable notification id derived from the med id
  /// and the time, so re-scheduling overwrites rather than duplicating. Uses
  /// `zonedSchedule` with `matchDateTimeComponents: time` so it repeats every
  /// day at the prescribed wall-clock time, and `exactAllowWhileIdle` so it
  /// fires on time even in Doze. Returns the number of reminders armed.
  Future<int> scheduleForToday(Medication med) async {
    if (!_available) return 0;
    var scheduled = 0;
    for (final t in med.scheduleTimes) {
      try {
        await _plugin.zonedSchedule(
          id: _reminderId(med.id, t.hour, t.minute),
          scheduledDate: _nextInstanceOf(t.hour, t.minute),
          title: 'Siyaphila · ${med.name}',
          body: 'Time for your ${med.dosageAmount} 💊',
          notificationDetails: _details(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        scheduled++;
      } catch (e) {
        debugPrint('schedule for ${med.name} @ ${t.hour}:${t.minute} failed: $e');
      }
    }
    return scheduled;
  }

  /// Cancels every scheduled reminder (used before a full reschedule / reset).
  Future<void> cancelAll() async {
    if (!_available) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('cancelAll failed: $e');
    }
  }

  /// The next occurrence of [hour]:[minute] in the device's local zone.
  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Deterministic, collision-resistant id for a given med + time-of-day.
  int _reminderId(String medId, int hour, int minute) =>
      (medId.hashCode ^ (hour * 60 + minute)) & 0x7fffffff;

  NotificationDetails _details() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
}
