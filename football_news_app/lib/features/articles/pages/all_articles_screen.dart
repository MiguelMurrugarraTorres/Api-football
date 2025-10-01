import 'package:flutter/material.dart';
import 'package:football_news_app/data/models/article.dart';
import 'package:football_news_app/features/home/widgets/article_card_widget.dart';
import 'package:football_news_app/features/home/widgets/bottom_navigation_widget.dart';
import 'package:football_news_app/features/home/widgets/first_article_widget.dart';
import 'package:football_news_app/features/webview/pages/in_app_webview_page.dart';
import 'package:football_news_app/data/services/api_service.dart';
import 'package:football_news_app/main.dart'; // para MyHomePageState

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
  void _openWeb(BuildContext context, String url, {String? title}) {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enlace vacío')),
      );
      return;
    }

    // Normalizar esquema (por si viene sin http/https)
    final normalized = url.startsWith('http://') || url.startsWith('https://')
        ? url
        : 'https://$url';

    // 1) Si estamos bajo MyHomePage, usar su pestaña WebView
    final homeState = context.findAncestorStateOfType<MyHomePageState>();
    if (homeState != null) {
      homeState.openWebView(normalized, title: title);
      return;
    }

    // 2) Fallback: push a la pantalla propia
    final uri = Uri.tryParse(normalized);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL inválida')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InAppWebViewPage(uri: uri, title: title),
      ),
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
              openWebView: (url) =>
                  _openWeb(context, url, title: articles[index].title),
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
