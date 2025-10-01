import 'package:flutter/material.dart';
import 'package:football_news_app/data/models/article.dart';
import 'package:football_news_app/data/services/api_service.dart';
import 'package:football_news_app/features/home/widgets/bottom_navigation_widget.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  bool _isSearching = false;

  // Resultados de búsqueda
  List<Map<String, dynamic>> teams = [];
  List<Map<String, dynamic>> news = [];

  // Sugerencias desde cache (artículos)
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
      // Cargamos hasta 10 sugerencias desde el cache
      final cached = await apiService.getCachedArticles(limit: 10);
      // Filtra artículos sin link utilizable
      final usable = cached.where((a) => (a.videoLink).trim().isNotEmpty).toList();
      if (!mounted) return;
      setState(() {
        suggestions = usable;
        _loadedSuggestions = true;
      });
    } catch (e) {
      debugPrint('Error loading suggestions: $e');
      if (!mounted) return;
      setState(() => _loadedSuggestions = true); // evita spinner infinito
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
      debugPrint('Error searching: $e');
      if (!mounted) return;
      setState(() => _isSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocurrió un error buscando')),
      );
    }
  }

  // Devolver {url, title} al Home
  void _returnResult({required String url, required String title}) {
    final link = url.trim();
    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enlace vacío')),
      );
      return;
    }

    final normalized = (link.startsWith('http://') || link.startsWith('https://'))
        ? link
        : 'https://$link';

    Navigator.pop(context, {
      'url': normalized,
      'title': title,
    });
  }

  Widget _buildTeamCard(Map<String, dynamic> team) {
    final String title = (team['text'] ?? '').toString();
    final String? img = team['img'] as String?;
    final String link = (team['link'] ?? '').toString();

    return ListTile(
      leading: img != null && img.isNotEmpty
          ? Image.network(
              img,
              width: 50,
              height: 50,
              errorBuilder: (_, __, ___) => const Icon(Icons.group),
            )
          : const Icon(Icons.group),
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      onTap: () => _returnResult(url: link, title: title),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> newsItem) {
    final String title = (newsItem['text'] ?? '').toString();
    final String? img = newsItem['img'] as String?;
    final String link = (newsItem['link'] ?? '').toString();

    return ListTile(
      leading: img != null && img.isNotEmpty
          ? Image.network(
              img,
              width: 50,
              height: 50,
              errorBuilder: (_, __, ___) => const Icon(Icons.article),
            )
          : const Icon(Icons.article),
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      onTap: () => _returnResult(url: link, title: title),
    );
  }

  // Sugerencias desde cache (artículos)
  Widget _buildSuggestionTile(Article a) {
    return ListTile(
      leading: (a.imageUrl.isNotEmpty)
          ? Image.network(
              a.imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined),
            )
          : const Icon(Icons.image_outlined),
      title: Text(
        a.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        a.source,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      ),
      onTap: () => _returnResult(url: a.videoLink, title: a.title),
    );
  }

  void _onBottomItemTapped(int index) {
    setState(() => _selectedIndexBottom = index);
    if (index != 0) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasResults = teams.isNotEmpty || news.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: TextField(
          controller: _searchController,
          onSubmitted: _search,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Escribe algo...',
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
            child: const Text('CANCELAR', style: TextStyle(color: Colors.blue)),
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
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'EQUIPOS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        ...teams.map(_buildTeamCard),
                      ],
                      if (news.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'NOTICIAS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        ...news.map(_buildNewsCard),
                      ],
                    ],
                  ),
                )
              : (_loadedSuggestions && suggestions.isNotEmpty)
                  ? RefreshIndicator(
                      onRefresh: () async => _loadSuggestions(),
                      child: ListView(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'SUGERENCIAS',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          ...suggestions.map(_buildSuggestionTile),
                          const SizedBox(height: 24),
                          const Center(
                            child: Text(
                              'Tip: usa el buscador para encontrar equipos o noticias específicas',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    )
                  : const Center(
                      child: Text(
                        'Busca equipos o noticias',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
      bottomNavigationBar: BottomNavigationWidget(
        selectedIndex: _selectedIndexBottom,
        onItemTapped: _onBottomItemTapped,
      ),
    );
  }
}
