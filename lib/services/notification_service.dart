import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Thin wrapper around flutter_local_notifications so screens can fire a
/// system notification (driver arrived, new ride request, etc.) with one
/// call. No-op on platforms without a local-notifications backend (web).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  int _nextId = 0;

  Future<void> init() async {
    if (_ready || kIsWeb) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    _ready = true;
  }

  Future<void> show(String title, String body) async {
    if (!_ready || kIsWeb) return;
    const androidDetails = AndroidNotificationDetails(
      'saika_events',
      'Saika alerts',
      channelDescription: 'Ride requests, arrivals, and other live events',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(_nextId++, title, body, details);
  }
}
