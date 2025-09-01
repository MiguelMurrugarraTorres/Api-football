import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:football_news_app/api_service.dart';
import 'package:football_news_app/main.dart'; // para MyHomePageState
import 'article.dart';
import 'article_card_widget.dart';
import 'first_article_widget.dart';
import 'bottom_navigation_widget.dart';

class AllArticlesScreen extends StatefulWidget {
  final List<Article> articles;

  const AllArticlesScreen({Key? key, required this.articles}) : super(key: key);

  @override
  _AllArticlesScreenState createState() => _AllArticlesScreenState();
}

class _AllArticlesScreenState extends State<AllArticlesScreen> {
  final ApiService apiService = ApiService();
  List<Article> articles = [];
  bool isLoadingMore = false;
  int currentLength = 0;
  final int increment = 10;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    articles = widget.articles;
    currentLength = articles.length;
    if (articles.isEmpty) {
      loadMoreArticles();
    }
  }

  Future<void> loadMoreArticles() async {
    setState(() => isLoadingMore = true);
    try {
      final List<Article> fetchedArticles = await apiService.fetchAllArticles();
      setState(() {
        articles.addAll(fetchedArticles);
        currentLength = articles.length;
        isLoadingMore = false;
      });
    } catch (error) {
      debugPrint('Error loading more articles: $error');
      setState(() => isLoadingMore = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Maneja navegación por categorías si lo necesitas
    });
  }

  // Abre URL dentro del app: si estamos bajo MyHomePage usa su WebView; si no, push a una pantalla propia
  void _openWeb(BuildContext context, String url) {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enlace vacío')),
      );
      return;
    }

    // 1) Si estamos bajo MyHomePage (pantalla principal), usa su IndexedStack
    final homeState = context.findAncestorStateOfType<MyHomePageState>();
    if (homeState != null) {
      homeState.openWebView(url);
      return;
    }

    // 2) Fallback: pantalla propia con WebView y back que respeta historial
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL inválida')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => InAppWebViewPage(uri: uri)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Articles'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (!isLoadingMore &&
              scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            loadMoreArticles();
          }
          return true;
        },
        child: ListView.builder(
          itemCount: articles.length,
          itemBuilder: (context, index) {
            if (index == 0 && articles.isNotEmpty) {
              return FirstArticleWidget(article: articles[index]);
            }
            return ArticleCardWidget(
              article: articles[index],
              openWebView: (url) => _openWeb(context, url),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationWidget(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

/// Pantalla de WebView con back que primero navega atrás en historial y recién luego sale.
/// Incluye BottomNavigationWidget al igual que Home.
/// NOTA: al tocar una pestaña aquí, volvemos al Home (raíz) para mantener coherencia.
class InAppWebViewPage extends StatefulWidget {
  final Uri uri;
  const InAppWebViewPage({Key? key, required this.uri}) : super(key: key);

  @override
  State<InAppWebViewPage> createState() => _InAppWebViewPageState();
}

class _InAppWebViewPageState extends State<InAppWebViewPage> {
  late final WebViewController _controller;

  // índice local solo para resaltar visualmente en esta pantalla
  int _selectedIndexBottom = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) => NavigationDecision.navigate,
        ),
      )
      ..loadRequest(widget.uri);
  }

  Future<bool> _handleWillPop() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false; // No cerrar la pantalla todavía
    }
    return true; // Cerrar la pantalla
  }

  void _onBottomItemTapped(int index) async {
    setState(() => _selectedIndexBottom = index);

    // Si existe MyHomePage como ancestro, volvemos a la raíz (Home).
    // Nota: No podemos tocar métodos privados del Home desde aquí,
    // pero al regresar al Home el usuario ya ve la barra y puede cambiar.
    final homeState = context.findAncestorStateOfType<MyHomePageState>();
    if (homeState != null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    // Si no hay Home en el stack (caso raro), al menos cerramos este WebView.
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _controller.canGoBack()) {
                _controller.goBack();
              } else {
                if (mounted) Navigator.of(context).pop();
              }
            },
          ),
          title: const Text(''),
        ),
        body: SizedBox.expand(
          child: WebViewWidget(controller: _controller),
        ),
        bottomNavigationBar: BottomNavigationWidget(
          selectedIndex: _selectedIndexBottom,
          onItemTapped: _onBottomItemTapped,
        ),
      ),
    );
  }
}