import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/geofence_zone.dart';

class NotificationService {
  static const _channelId = 'smart_silencer_geofence';
  static const _channelName = 'Geofence Events';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);
  }

  static Future<void> showZoneEntered(GeofenceZone zone) async {
    final modeLabel =
        zone.silenceMode == SilenceMode.silent ? 'Silent' : 'Vibrate';
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Alerts when entering or exiting geofence zones',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
    await _plugin.show(
      zone.id.hashCode & 0x7FFFFFFF,
      '📍 Entered: ${zone.name}',
      'Phone set to $modeLabel mode automatically',
      const NotificationDetails(android: androidDetails),
    );
  }

  static Future<void> showZoneExited(GeofenceZone zone) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Alerts when entering or exiting geofence zones',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
    await _plugin.show(
      (zone.id.hashCode & 0x7FFFFFFF) + 1,
      '🔔 Exited: ${zone.name}',
      'Phone restored to normal mode',
      const NotificationDetails(android: androidDetails),
    );
  }
}
