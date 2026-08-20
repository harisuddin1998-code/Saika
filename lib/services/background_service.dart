import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Keeps the app process alive with an Android foreground service + a
/// persistent "you're online" notification, so the realtime WebSocket
/// connection survives the screen locking or the app being backgrounded —
/// without this, Android eventually suspends the isolate and ride
/// requests / arrival alerts stop arriving.
class BackgroundService {
  BackgroundService._();

  static void init() {
    if (kIsWeb) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'saika_online',
        channelName: 'Saika — staying online',
        channelDescription: 'Keeps you connected so ride events arrive in real time.',
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
      ),
    );
  }

  static Future<void> start({required String title, required String text}) async {
    if (kIsWeb) return;
    final granted = await FlutterForegroundTask.checkNotificationPermission();
    if (granted != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: title,
      notificationText: text,
      callback: _startCallback,
    );
  }

  static Future<void> stop() async {
    if (kIsWeb) return;
    await FlutterForegroundTask.stopService();
  }
}

@pragma('vm:entry-point')
void _startCallback() {
  FlutterForegroundTask.setTaskHandler(_IdleTaskHandler());
}

class _IdleTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}
