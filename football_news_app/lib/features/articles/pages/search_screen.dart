import 'package:flutter/material.dart';
import 'package:football_news_app/data/models/article.dart';
import 'package:football_news_app/data/services/api_service.dart';
import 'package:football_news_app/features/home/widgets/bottom_navigation_widget.dart';
import 'package:football_news_app/features/webview/pages/in_app_webview_page.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  bool _isSearching = false;

  // Resultados
  List<Map<String, dynamic>> teams = [];
  List<Map<String, dynamic>> news = [];

  // Sugerencias
  List<Article> suggestions = [];
  bool _loadedSuggestions = false;

  int _selectedIndexBottom = 0;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    try {
      final cached = await apiService.getCachedArticles(limit: 10);
      final usable = cached.where((a) => a.videoLink.trim().isNotEmpty).toList();
      if (!mounted) return;
      setState(() {
        suggestions = usable;
        _loadedSuggestions = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadedSuggestions = true);
    }
  }

  Future<void> _search([String? raw]) async {
    final query = (raw ?? _searchController.text).trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final fetchedTeams = await apiService.searchTeams(query);
      final fetchedNews = await apiService.searchNews(query);

      if (!mounted) return;
      setState(() {
        teams = fetchedTeams;
        news = fetchedNews;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocurrió un error buscando')),
      );
    }
  }

  // Abre WebView directamente (en esta pantalla)
  void _openInlineWeb(String url, {required String title}) {
    final link = url.trim();
    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enlace vacío')),
      );
      return;
    }
    final normalized =
        (link.startsWith('http://') || link.startsWith('https://')) ? link : 'https://$link';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InAppWebViewPage(uri: Uri.parse(normalized), title: title),
      ),
    );
  }

  // ==== UI helpers ====

  Widget _sectionHeader(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _teamTile(BuildContext context, Map<String, dynamic> team) {
    final scheme = Theme.of(context).colorScheme;
    final String title = (team['text'] ?? '').toString();
    final String? img = team['img'] as String?;
    final String link = (team['link'] ?? '').toString();

    return ListTile(
      leading: (img != null && img.isNotEmpty)
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                img,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _squarePlaceholder(scheme),
              ),
            )
          : _squarePlaceholder(scheme),
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      onTap: () => _openInlineWeb(link, title: title),
    );
  }

  Widget _newsTile(BuildContext context, Map<String, dynamic> item) {
    final scheme = Theme.of(context).colorScheme;
    final String title = (item['text'] ?? '').toString();
    final String? img = item['img'] as String?;
    final String link = (item['link'] ?? '').toString();

    return ListTile(
      leading: (img != null && img.isNotEmpty)
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                img,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _squarePlaceholder(scheme),
              ),
            )
          : _squarePlaceholder(scheme),
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      onTap: () => _openInlineWeb(link, title: title),
    );
  }

  Widget _suggestionTile(BuildContext context, Article a) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: (a.imageUrl.isNotEmpty)
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                a.imageUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _squarePlaceholder(scheme),
              ),
            )
          : _squarePlaceholder(scheme),
      title: Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: (a.source.isNotEmpty)
          ? Text(
              a.source,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            )
          : null,
      onTap: () => _openInlineWeb(a.videoLink, title: a.title),
    );
  }

  Widget _squarePlaceholder(ColorScheme scheme) => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: scheme.surfaceVariant,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(Icons.image_outlined, color: scheme.onSurfaceVariant, size: 20),
      );

  void _onBottomItemTapped(int index) {
    setState(() => _selectedIndexBottom = index);
    if (index != 0) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasResults = teams.isNotEmpty || news.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: scheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            onSubmitted: _search,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Escribe algo...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Buscar',
            onPressed: () => _search(),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Limpiar',
            onPressed: () {
              _searchController.clear();
              setState(() {
                teams.clear();
                news.clear();
              });
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCELAR', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : hasResults
              ? RefreshIndicator(
                  onRefresh: () async => _search(),
                  child: ListView(
                    children: [
                      if (teams.isNotEmpty) ...[
                        _sectionHeader(context, 'EQUIPOS'),
                        ...teams.map((t) => _teamTile(context, t)),
                      ],
                      if (news.isNotEmpty) ...[
                        _sectionHeader(context, 'NOTICIAS'),
                        ...news.map((n) => _newsTile(context, n)),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                )
              : (_loadedSuggestions && suggestions.isNotEmpty)
                  ? RefreshIndicator(
                      onRefresh: () async => _loadSuggestions(),
                      child: ListView(
                        children: [
                          _sectionHeader(context, 'SUGERENCIAS'),
                          ...suggestions.map((a) => _suggestionTile(context, a)),
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Tip: usa el buscador para encontrar equipos o noticias específicas',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Busca equipos o noticias',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ),
      bottomNavigationBar: BottomNavigationWidget(
        selectedIndex: _selectedIndexBottom,
        onItemTapped: _onBottomItemTapped,
      ),
    );
  }
}
