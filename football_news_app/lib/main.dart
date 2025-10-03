import 'dart:convert';
import 'dart:io' as io;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:football_news_app/data/models/article.dart';
import 'package:football_news_app/data/services/api_service.dart';
import 'package:football_news_app/features/articles/pages/all_articles_screen.dart';
import 'package:football_news_app/features/articles/pages/search_screen.dart';
import 'package:football_news_app/features/home/pages/splash_screen.dart';
import 'package:football_news_app/shared/widgets/extensions/under_construction.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'features/home/widgets/article_card_widget.dart';
import 'features/home/widgets/bottom_navigation_widget.dart';
import 'features/home/widgets/first_article_widget.dart';

/// ⚠️ Solo desarrollo: aceptar todos los certificados.
class MyHttpOverrides extends io.HttpOverrides {
  @override
  io.HttpClient createHttpClient(io.SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback =
        (io.X509Certificate cert, String host, int port) => true;
    return client;
  }
}

/// ---------- Notificaciones: setup global ----------

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Se llama cuando llega una push con la app en background/terminada
  await Firebase.initializeApp();
  // Aquí puedes hacer logging si quieres
}

// Canal Android para mostrar notifs locales cuando la app está en foreground
const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Canal para notificaciones importantes',
  importance: Importance.high,
);

final FlutterLocalNotificationsPlugin _localNotifs =
    FlutterLocalNotificationsPlugin();

Future<void> _setupLocalNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const init = InitializationSettings(android: androidInit);

  await _localNotifs.initialize(init
      // Si quieres abrir una URL al tocar una notif local en foreground,
      // añade onDidReceiveNotificationResponse y maneja un payload.
      // , onDidReceiveNotificationResponse: (resp) {
      //   final payload = resp.payload;
      //   // aquí podrías guardar el payload globalmente y consumirlo luego.
      // }
      );

  await _localNotifs
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_androidChannel);
}

Future<void> _requestNotificationPermission() async {
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  debugPrint('Permiso notificaciones: ${settings.authorizationStatus}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Handlers globales
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await _setupLocalNotifications();
  await _requestNotificationPermission();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Football News App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final ApiService apiService = ApiService();

  List<Article> articles = [];
  List<Article> cachedArticles = [];
  bool isLoading = false;

  int _selectedIndex = 0;

  // 👉 Estado para el tab WebView integrado
  String? _webUrl;
  String? _webTitle;
  WebViewController? _inAppWebController;

  List<String> categories = ['Inicio'];
  String? _wipCategory;

  @override
  void initState() {
    super.initState();
    _initData();
    _setupFCMCallbacks(); // 👈 inicializa handlers FCM
  }

  Future<void> _initData() async {
    await loadCachedArticles();
    await fetchAllArticles();
    await fetchCategories();
  }

  /// ---------- FCM: listeners que abren el WebView ----------
  void _setupFCMCallbacks() async {
    // (Opcional) suscripción a un topic
    await FirebaseMessaging.instance.subscribeToTopic('news');

    // 1) Si la app se abre desde terminada por una push (cold start)
    final initialMsg = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMsg != null) {
      _handleNotificationTap(initialMsg);
    }

    // 2) Tap en una notificación cuando la app estaba en background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });

    // 3) Mensajes en foreground -> muestra notificación local
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final notif = message.notification;
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
          payload: message.data['url'], // si quieres usarlo luego
        );
      }
    });
  }

  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final String? url = (data['url'] ?? '').toString().trim().isEmpty
        ? null
        : data['url'] as String;
    final String? title = (data['title'] as String?)?.trim();

    if (url != null) {
      // Normaliza
      final normalized = (url.startsWith('http://') || url.startsWith('https://'))
          ? url
          : 'https://$url';
      openWebView(normalized, title: title ?? message.notification?.title);
    }
  }

  // ------------------ DATA ------------------

  Future<void> loadCachedArticles() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('initialArticles');
    if (cachedData != null) {
      final List<Article> cached = (jsonDecode(cachedData) as List)
          .map((data) => Article.fromJson(data))
          .toList();
      setState(() {
        articles = cached;
      });
    }
  }

  Future<void> fetchAllArticles() async {
    try {
      final fetched = await apiService.fetchAllArticles();
      setState(() {
        cachedArticles = fetched;
        articles = fetched;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching all articles: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchCategories() async {
    try {
      final fetchedCategories = await apiService.fetchCategories();
      setState(() {
        categories = ['Inicio', ...fetchedCategories];
      });
    } catch (error) {
      debugPrint('Error fetching categories: $error');
    }
  }

  // ------------------ NAV ------------------

  void _onItemTapped(int index) {
    setState(() {
      if (index == 0) {
        _selectedIndex = 0;
        _wipCategory = null;
        _webUrl = null;
        _webTitle = null;
      } else {
        _selectedIndex = 2; // placeholder
        _webUrl = null;
        _webTitle = null;
        _wipCategory = (index < categories.length) ? categories[index] : null;
      }
    });
  }

  void openWebView(String url, {String? title}) {
    setState(() {
      _webUrl = url;
      _webTitle = title;
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayed =
        articles.length > 7 ? articles.take(7).toList() : articles;

    final String appBarTitle =
        _webUrl != null ? (_webTitle ?? 'PREMIERFOOTBALL') : 'PREMIERFOOTBALL';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appBarTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
              // Compat: soporta String o Map {url,title}
              if (result is Map) {
                final url = (result['url'] ?? '').toString();
                final String? title = (result['title'] as String?)?.trim();
                if (url.isNotEmpty) openWebView(url, title: title);
              } else if (result is String && result.isNotEmpty) {
                openWebView(result);
              }
            },
          ),
        ],
        leading: _webUrl != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  if (_inAppWebController != null &&
                      await _inAppWebController!.canGoBack()) {
                    _inAppWebController!.goBack();
                  } else {
                    setState(() {
                      _webUrl = null;
                      _webTitle = null;
                    });
                  }
                },
              )
            : null,
      ),
      body: IndexedStack(
        index: _webUrl == null ? _selectedIndex : 1,
        children: [
          // 0) Home
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: fetchAllArticles,
                  child: ListView.builder(
                    itemCount: displayed.isEmpty ? 1 : displayed.length + 1,
                    itemBuilder: (context, index) {
                      if (displayed.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text('No articles available.'),
                          ),
                        );
                      } else if (index == 0) {
                        return FirstArticleWidget(article: displayed[index]);
                      } else if (index == displayed.length) {
                        return Center(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AllArticlesScreen(
                                    articles: cachedArticles.isNotEmpty
                                        ? cachedArticles
                                        : articles,
                                  ),
                                ),
                              );
                            },
                            child: const Text('Ver más'),
                          ),
                        );
                      } else {
                        return ArticleCardWidget(
                          article: displayed[index],
                          openWebView: openWebView,
                        );
                      }
                    },
                  ),
                ),

          // 1) WebView integrado
          _webUrl != null
              ? SizedBox.expand(
                  child: WebViewWidget(
                    controller: (_inAppWebController = WebViewController()
                      ..setJavaScriptMode(JavaScriptMode.unrestricted)
                      ..loadRequest(Uri.parse(_webUrl!))),
                  ),
                )
              : const SizedBox.shrink(),

          // 2) Placeholder "En construcción"
          UnderConstruction(
            label: _wipCategory,
            onGoHome: () => _onItemTapped(0),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationWidget(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
