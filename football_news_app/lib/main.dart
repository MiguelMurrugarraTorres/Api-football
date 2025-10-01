import 'dart:convert';
import 'dart:io' as io; // 👈 alias para evitar conflicto con webview
import 'package:flutter/material.dart';
import 'package:football_news_app/data/services/api_service.dart';
import 'package:football_news_app/data/models/article.dart';
import 'package:football_news_app/features/articles/pages/all_articles_screen.dart';
import 'package:football_news_app/features/articles/pages/search_screen.dart';
import 'package:football_news_app/shared/widgets/extensions/under_construction.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'features/home/widgets/article_card_widget.dart';
import 'features/home/widgets/bottom_navigation_widget.dart';
import 'features/home/widgets/first_article_widget.dart';

// ⚠️ Solo para desarrollo: acepta todos los certificados.
class MyHttpOverrides extends io.HttpOverrides {
  @override
  io.HttpClient createHttpClient(io.SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback =
        (io.X509Certificate cert, String host, int port) => true;
    return client;
  }
}

void main() {
  // io.HttpOverrides.global = MyHttpOverrides(); // ⚠️ quitar en producción
  runApp(MyApp());
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
      home: const MyHomePage(),
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
  String? _webTitle;                  // 🔹 nuevo: título opcional para el AppBar del WebView
  WebViewController? _inAppWebController;

  List<String> categories = ['Inicio'];

  @override
  void initState() {
    super.initState();
    loadCachedArticles();
    fetchAllArticles();
    fetchCategories();
  }

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

  Future<void> fetchInitialArticles() async {
    setState(() {
      isLoading = true;
    });
    try {
      final fetchedArticles = await apiService.fetchInitialArticles();
      setState(() {
        articles = fetchedArticles;
        isLoading = false;
      });
      fetchAllArticles();
    } catch (error) {
      debugPrint('Error fetching initial articles: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchAllArticles() async {
    try {
      final fetched = await apiService.fetchAllArticles();
      setState(() {
        cachedArticles = fetched;
        articles = fetched; // ✅ Home usa BD
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


String? _wipCategory; // nombre de la categoría seleccionada (≠ Inicio)

void _onItemTapped(int index) {
  setState(() {
    if (index == 0) {
      _selectedIndex = 0;
      _wipCategory = null;
      _webUrl = null;
      _webTitle = null;
    } else {
      // siempre mostramos el placeholder en el child #2
      _selectedIndex = 2;
      _webUrl = null;
      _webTitle = null;
      // usa las categorías que ya cargas en MyHomePage
      _wipCategory = (index < categories.length) ? categories[index] : null;
    }
  });
}


  // 🔹 Opción A: agrega título opcional
  void openWebView(String url, {String? title}) {
    setState(() {
      _webUrl = url;
      _webTitle = title; // puede venir nulo y no pasa nada
      // Nota: el IndexedStack ya muestra el WebView cuando _webUrl != null
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayed =
        articles.length > 7 ? articles.take(7).toList() : articles;

    // Título dinámico: muestra el del artículo cuando estás en WebView
      String appBarTitle;
      if (_webUrl != null) {
        appBarTitle = _webTitle ?? 'PREMIERFOOTBALL';
      } else {
        appBarTitle = 'PREMIERFOOTBALL';
      }

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
              if (result is String && result.isNotEmpty) {
                openWebView(result); // puedes pasar title: si lo tienes
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
                          // Desde Home, normalmente no pasas título (igual soporta el param)
                          openWebView: openWebView,
                        );
                      }
                    },
                  ),
                ),

          // 1) WebView integrado en el IndexedStack
          _webUrl != null
              ? SizedBox.expand(
                  child: WebViewWidget(
                    controller: (_inAppWebController = WebViewController()
                      ..setJavaScriptMode(JavaScriptMode.unrestricted)
                      ..loadRequest(Uri.parse(_webUrl!))),
                  ),
                )
              : const SizedBox.shrink(),

          // 2) Otra Sección (placeholder)
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
