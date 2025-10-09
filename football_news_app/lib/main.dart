// lib/main.dart
import 'dart:convert';
import 'dart:io' as io;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Intl (para los chips de fecha en Matches)
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

// Tu modelo/servicios existentes
import 'package:football_news_app/data/models/article.dart';
import 'package:football_news_app/data/services/api_service.dart';

// Pantallas existentes
import 'package:football_news_app/features/articles/pages/all_articles_screen.dart';
import 'package:football_news_app/features/articles/pages/search_screen.dart';
import 'package:football_news_app/features/home/pages/splash_screen.dart';
import 'package:football_news_app/shared/widgets/extensions/under_construction.dart';

// Widgets de Home
import 'features/home/widgets/article_card_widget.dart';
import 'features/home/widgets/bottom_navigation_widget.dart';
import 'features/home/widgets/first_article_widget.dart';

// Servicios de notificaciones
import 'package:football_news_app/data/services/push_service.dart';
import 'package:football_news_app/core/notifications/local_notifications.dart';
import 'package:football_news_app/core/notifications/fcm_background.dart';

// Pantalla de Partidos (real)
import 'package:football_news_app/features/matches/pages/matches_screen.dart';

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

/// GlobalKey para poder abrir el WebView integrado desde PushService
final GlobalKey<MyHomePageState> homeKey = GlobalKey<MyHomePageState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  io.HttpOverrides.global = MyHttpOverrides(); // si lo usas en dev

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await setupLocalNotifications();

  // ===== Intl: locale para fechas (evita LocaleDataException) =====
  Intl.defaultLocale = 'es_PE';
  await initializeDateFormatting('es_PE', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static bool _pushInit = false; // guard

  @override
  Widget build(BuildContext context) {
    // Inicializamos PushService (idempotente, registra SOLO una vez)
    final push = PushService(localNotifs, androidHighImportanceChannel);

    if (!_pushInit) {
      _pushInit = true;

      // Enlaza taps de notificación -> abrir WebView del Home
      push.bindNotificationTaps(
        openFromOutside: (url, {String? title}) async {
          final state = homeKey.currentState;
          if (state != null) state.openWebView(url, title: title);
        },
      );

      // Pide permisos, obtiene token y registra device en backend
      push.initAndRegister();
    }

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
      routes: {
        '/home': (_) => MyHomePage(key: homeKey), // 👈 sin const
        '/matches': (_) => const MatchesScreen(), // 👈 pantalla real
        '/teams': (_) => const _TeamsFallback(), // temporal
        // puedes agregar '/tv', '/bets', etc. cuando estén listas
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => UnderConstruction(
          label: settings.name ?? 'Sección',
          onGoHome: () => Navigator.of(_).pushReplacementNamed('/home'),
        ),
      ),
    );
  }
}

/// ===================== HOME =====================
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
  }

  Future<void> _initData() async {
    await loadCachedArticles();
    await fetchAllArticles();
    await fetchCategories();
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
      setState(() => isLoading = true);
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

  Future<void> openWebView(String url, {String? title}) async {
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

/// ====== Fallback temporal para Teams (cámbialo cuando tengas la pantalla real) ======
class _TeamsFallback extends StatelessWidget {
  const _TeamsFallback();

  @override
  Widget build(BuildContext context) {
    return UnderConstruction(
      label: 'Equipos',
      onGoHome: () => Navigator.of(context).pushReplacementNamed('/home'),
    );
  }
}
