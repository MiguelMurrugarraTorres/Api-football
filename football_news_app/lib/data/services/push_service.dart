import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:football_news_app/app/app_const.dart';
import 'package:http/http.dart' as http;


import 'auth_service.dart';

/// Firma para abrir WebView del Home desde fuera
typedef OpenFromOutside = Future<void> Function(String url, {String? title});

class PushService {
  final FlutterLocalNotificationsPlugin _localNotifs;
  final AndroidNotificationChannel _androidChannel;

  PushService(this._localNotifs, this._androidChannel);

  OpenFromOutside? _openFromOutside;

  /// Vincula las acciones de taps de notificaciones (cold start + background)
  void bindNotificationTaps({required OpenFromOutside openFromOutside}) {
    _openFromOutside = openFromOutside;

    // Cold start
    FirebaseMessaging.instance.getInitialMessage().then((msg) {
      if (msg != null) _handleNotificationTap(msg);
    });

    // Background -> tap
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      _handleNotificationTap(msg);
    });

    // Foreground -> mostrar notificación local
    FirebaseMessaging.onMessage.listen((msg) async {
      final notif = msg.notification;
      final android = notif?.android;
      if (notif != null && android != null) {
        await _localNotifs.show(
          notif.hashCode,
          notif.title,
          notif.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          payload: msg.data['url'],
        );
      }
    });
  }

  /// Pide permiso, obtiene token, asegura userId y registra el device en tu backend.
  Future<void> initAndRegister() async {
    try {
      // 1) Permisos (Android 13+/iOS)
      await _requestNotificationPermission();

      // 2) Suscribe opcional a topic
      await FirebaseMessaging.instance.subscribeToTopic('news');

      // 3) Token actual
      final token = await FirebaseMessaging.instance.getToken();
      debugPrint('[PushService] FCM token: $token');

      // 4) Asegura usuario anónimo
      final auth = AuthService();
      final userId = await auth.ensureAnonUser();
      if (userId == null || token == null || token.isEmpty) {
        debugPrint('[PushService] cannot register FCM: userId=$userId token=$token');
        return;
      }

      // 5) Registrar device en backend
      await _registerDevice(userId: userId, token: token);

      // 6) Manejar refresh de token
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        debugPrint('[PushService] FCM token refresh: $newToken');
        final uid = await auth.getStoredUserId();
        if (uid != null && newToken.isNotEmpty) {
          await _registerDevice(userId: uid, token: newToken);
        }
      });
    } catch (e, st) {
      debugPrint('[PushService] initAndRegister ERR: $e\n$st');
    }
  }

  // ---- Privados ----

  Future<void> _requestNotificationPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
    debugPrint('[PushService] permiso: ${settings.authorizationStatus}');
  }

  Future<void> _registerDevice({required int userId, required String token}) async {
    try {
      final platform =
          Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web');

      final resp = await http
          .post(
            Uri.parse('${AppConst.protectedApiBase}/devices/register'),
            headers: AppConst.headers(),
            body: jsonEncode({
              'userId': userId,
              'token': token,
              'platform': platform,
              'appId': AppConst.appId, // 'premierfootball'
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (resp.statusCode != 200) {
        debugPrint('[PushService] registerDevice http=${resp.statusCode} body=${resp.body}');
        return;
      }
      final map = jsonDecode(resp.body) as Map<String, dynamic>;
      if (map['b_Activo'] != true) {
        debugPrint('[PushService] registerDevice server msg=${map['responseMessage']}');
      } else {
        debugPrint('[PushService] device registrado OK');
      }
    } catch (e, st) {
      debugPrint('[PushService] registerDevice ERR: $e\n$st');
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final String? url = (data['url'] ?? '').toString().trim().isEmpty
        ? null
        : data['url'] as String;
    final String? title = (data['title'] as String?)?.trim();

    if (url != null && _openFromOutside != null) {
      final normalized = (url.startsWith('http://') || url.startsWith('https://'))
          ? url
          : 'https://$url';
      _openFromOutside!.call(normalized, title: title ?? message.notification?.title);
    }
  }
}
