// lib/main.dart
import 'dart:io' as io;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:football_news_app/app/theme/app_theme.dart';

// Rutas/pantallas
import 'package:football_news_app/features/home/pages/splash_screen.dart';
import 'package:football_news_app/features/home/pages/home_page.dart';
import 'package:football_news_app/features/teams/pages/teams_screen.dart';
import 'package:football_news_app/features/matches/pages/matches_screen.dart';
import 'package:football_news_app/shared/widgets/extensions/under_construction.dart';

// Notificaciones
import 'package:football_news_app/core/notifications/local_notifications.dart';
import 'package:football_news_app/core/notifications/fcm_background.dart';
import 'package:football_news_app/data/services/push_service.dart';

// ====== DEV: aceptar todos los certificados (si lo usas)
class MyHttpOverrides extends io.HttpOverrides {
  @override
  io.HttpClient createHttpClient(io.SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback =
        (io.X509Certificate cert, String host, int port) => true;
    return client;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  io.HttpOverrides.global = MyHttpOverrides(); // opcional dev

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await setupLocalNotifications();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  static bool _pushInit = false;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    if (!MyApp._pushInit) {
      MyApp._pushInit = true;
      final push = PushService(localNotifs, androidHighImportanceChannel);
      // Los taps abren el WebView integrado de Home
      push.bindNotificationTaps(openFromOutside: (url, {String? title}) async {
        homeKey.currentState?.openWebView(url, title: title);
      });
      push.initAndRegister();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Football News App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,

      // 🌍 Localización global
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
        Locale('pt'),
        Locale('fr'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: const SplashScreen(), // hace pushReplacement a HomePage(homeKey)

      routes: {
        '/home': (_) => const HomePage(),        // ← sin key aquí
        '/matches': (_) => const MatchesScreen(),
        '/teams': (_) => const TeamsScreen(),
        '/competitions': (context) => Scaffold(
              appBar: AppBar(title: const Text('Competiciones')),
              body: const UnderConstruction(label: 'Competiciones'),
            ),
        '/bets': (context) => Scaffold(
              appBar: AppBar(title: const Text('Apuestas')),
              body: const UnderConstruction(label: 'Apuestas'),
            ),
      },

      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (ctx) => UnderConstruction(
          label: settings.name ?? 'Sección',
          onGoHome: () => Navigator.of(ctx).popUntil((r) => r.isFirst),
        ),
      ),
    );
  }
}
