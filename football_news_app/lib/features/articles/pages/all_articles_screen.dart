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
  State<AllArticlesScreen> createState() => _AllArticlesScreenState();
}

class _AllArticlesScreenState extends State<AllArticlesScreen> {
  final ApiService apiService = ApiService();

  // Lista total y lista visible (paginación local)
  final int _pageSize = 10;
  List<Article> _all = [];
  List<Article> _visible = [];

  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  int _selectedIndex = 0;

  final ScrollController _scrollController = ScrollController();
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _all = List<Article>.from(widget.articles);
    _rebuildVisible(reset: true);
    _scrollController.addListener(_onScrollReachEnd);

    // Refresco silencioso para traer lo más nuevo sin bloquear UI
    _refreshSilently();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollReachEnd);
    _scrollController.dispose();
    super.dispose();
  }

  void _rebuildVisible({bool reset = false}) {
    if (reset) _visible = [];
    final nextCount = (_visible.length + _pageSize).clamp(0, _all.length);
    _visible = _all.take(nextCount).toList();
    setState(() {});
  }

  Future<void> _refreshSilently() async {
    try {
      final fresh = await apiService.fetchAllArticles();
      // Evita duplicados simples por URL si existe, si no por título.
      final seen = <String>{};
      _all = fresh.where((a) {
        final key =
            (a.imageUrl?.isNotEmpty == true ? a.imageUrl! : a.title).trim();
        if (seen.contains(key)) return false;
        seen.add(key);
        return true;
      }).toList();
      _errorMsg = null;
      _rebuildVisible(reset: true);
    } catch (e) {
      // No bloqueamos UX; solo guardamos el error para mostrar si lista vacía
      _errorMsg = '$e';
      if (_all.isEmpty) setState(() {}); // fuerza repaint si no hay nada
    }
  }

  Future<void> _onPullToRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final fresh = await apiService.fetchAllArticles();
      final seen = <String>{};
      _all = fresh.where((a) {
        final key =
            (a.imageUrl?.isNotEmpty == true ? a.imageUrl! : a.title).trim();
        if (seen.contains(key)) return false;
        seen.add(key);
        return true;
      }).toList();
      _errorMsg = null;
      _rebuildVisible(reset: true);
    } catch (e) {
      _errorMsg = '$e';
      if (_all.isEmpty) {
        // Fallback duro: intentar caché local por si acaso
        final cached = await apiService.getCachedArticles(limit: 50);
        if (cached.isNotEmpty) {
          _all = cached;
          _rebuildVisible(reset: true);
        }
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _onScrollReachEnd() {
    if (_isLoadingMore) return;
    if (!_scrollController.hasClients) return;
    final atEnd = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 80;
    if (!atEnd) return;

    // Si ya mostramos todo, no hacer nada
    if (_visible.length >= _all.length) return;

    setState(() => _isLoadingMore = true);
    Future.delayed(const Duration(milliseconds: 200), () {
      _rebuildVisible();
      if (mounted) setState(() => _isLoadingMore = false);
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    // Aquí luego enrutarás a Equipos / Partidos / Favoritos según index
  }

  // Abre URL dentro del app: si estamos bajo MyHomePage usa su WebView; si no, push a pantalla propia
  void _openWeb(BuildContext context, String url, {String? title}) {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enlace vacío')),
      );
      return;
    }

    final normalized = url.startsWith('http://') || url.startsWith('https://')
        ? url
        : 'https://$url';

    final homeState = context.findAncestorStateOfType<MyHomePageState>();
    if (homeState != null) {
      homeState.openWebView(normalized, title: title);
      return;
    }

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
    final showEmpty = _visible.isEmpty && !_isRefreshing && _errorMsg == null;
    final showError = _visible.isEmpty && _errorMsg != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Noticias'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onPullToRefresh,
        child: Builder(
          builder: (_) {
            if (showError) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Icon(Icons.wifi_off, size: 56, color: Colors.grey.shade600),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'No se pudieron cargar las noticias.\n$_errorMsg',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              );
            }

            if (showEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Icon(Icons.article_outlined,
                      size: 56, color: Colors.grey.shade600),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Aún no hay noticias para mostrar.',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              controller: _scrollController,
              itemCount: _visible.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == 0 && _visible.isNotEmpty) {
                  return FirstArticleWidget(article: _visible[index]);
                }
                if (index < _visible.length) {
                  final art = _visible[index];
                  return ArticleCardWidget(
                    article: art,
                    openWebView: (url) =>
                        _openWeb(context, url, title: art.title),
                  );
                }
                // Loader al final
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              },
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
