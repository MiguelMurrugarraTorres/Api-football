import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:football_news_app/api_service.dart';
import 'package:football_news_app/article.dart';
import 'package:football_news_app/article_card_widget.dart';
import 'package:football_news_app/first_article_widget.dart';
import 'package:football_news_app/all_articles_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'bottom_navigation_widget.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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

WebViewController? _inAppWebController; // arriba, como campo

class MyHomePageState extends State<MyHomePage> {
  ApiService apiService = ApiService();
  List<Article> articles = [];
  List<Article> cachedArticles = [];
  bool isLoading = false;
  int _selectedIndex = 0;
  String? _webUrl;
  List<String> categories = ['Inicio'];

  @override
  void initState() {
    super.initState();
    loadCachedArticles();
    fetchAllArticles();
    fetchCategories();
  }

  Future<void> loadCachedArticles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedData = prefs.getString('initialArticles');
    if (cachedData != null) {
      List<Article> cachedArticles = (jsonDecode(cachedData) as List)
          .map((data) => Article.fromJson(data))
          .toList();
      setState(() {
        articles = cachedArticles;
      });
    }
  }

  Future<void> fetchInitialArticles() async {
    setState(() {
      isLoading = true;
    });
    try {
      List<Article> fetchedArticles = await apiService.fetchInitialArticles();
      setState(() {
        articles = fetchedArticles;
        isLoading = false;
      });
      fetchAllArticles();
    } catch (error) {
      print('Error fetching initial articles: $error');
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
      List<String> fetchedCategories = await apiService.fetchCategories();
      setState(() {
        categories = ['Inicio'] + fetchedCategories;
      });
    } catch (error) {
      print('Error fetching categories: $error');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _webUrl = null; // Si el usuario cambia de pestaña, ocultar el WebView
    });
  }

  void openWebView(String url) {
    setState(() {
      _webUrl = url;
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayed =
        articles.length > 7 ? articles.take(7).toList() : articles;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PREMIERFOOTBALL',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: _webUrl != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  if (_inAppWebController != null &&
                      await _inAppWebController!.canGoBack()) {
                    _inAppWebController!.goBack();
                  } else {
                    setState(() => _webUrl = null);
                  }
                },
              )
            : null,
      ),
      body: IndexedStack(
        index: _webUrl == null ? _selectedIndex : 1,
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: fetchAllArticles,
                  child: ListView.builder(
                    itemCount: displayed.isEmpty ? 1 : displayed.length + 1,
                    itemBuilder: (context, index) {
                      if (displayed.isEmpty) {
                        return const Center(
                            child: Text('No articles available.'));
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
          _webUrl != null
              ? SizedBox.expand(
                  child: WebViewWidget(
                    controller: (_inAppWebController = WebViewController()
                      ..setJavaScriptMode(JavaScriptMode.unrestricted)
                      ..loadRequest(Uri.parse(_webUrl!))),
                  ),
                )
              : const SizedBox.shrink(),
          const Center(child: Text('Otra Sección')),
        ],
      ),
      bottomNavigationBar: BottomNavigationWidget(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
