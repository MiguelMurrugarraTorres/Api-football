// lib/core/notifications/local_notifications.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Canal Android para notifs locales (mismo que tenías en main.dart)
const AndroidNotificationChannel androidHighImportanceChannel =
    AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Canal para notificaciones importantes',
  importance: Importance.high,
);

/// Plugin único (singleton simple)
final FlutterLocalNotificationsPlugin localNotifs =
    FlutterLocalNotificationsPlugin();

/// Inicializa el plugin y crea el canal Android.
Future<void> setupLocalNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const init = InitializationSettings(android: androidInit);

  await localNotifs.initialize(init);

  await localNotifs
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(androidHighImportanceChannel);
}
