import 'package:flutter/material.dart';
import 'package:football_news_app/api_service.dart';
import 'package:football_news_app/main.dart'; // para MyHomePageState.openWebView
import 'package:webview_flutter/webview_flutter.dart'; // fallback WebView
import 'bottom_navigation_widget.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  bool _isSearching = false;
  List<Map<String, dynamic>> teams = [];
  List<Map<String, dynamic>> news = [];

  // Índice de la barra inferior en esta pantalla. Normalmente el Home es "Inicio" (0).
  int _selectedIndexBottom = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _openUrl(String url) {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enlace vacío')),
      );
      return;
    }
    Navigator.pop(context, url); // 👈 devolvemos la URL al Home
  }

  Widget _buildTeamCard(Map<String, dynamic> team) {
    final String title = (team['text'] ?? '').toString();
    final String? img = team['img'] as String?;
    final String link = (team['link'] ?? '').toString();

    return ListTile(
      leading: img != null && img.isNotEmpty
          ? Image.network(img, width: 50, height: 50)
          : const Icon(Icons.group),
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      onTap: () => _openUrl(link),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> newsItem) {
    final String title = (newsItem['text'] ?? '').toString();
    final String? img = newsItem['img'] as String?;
    final String link = (newsItem['link'] ?? '').toString();

    return ListTile(
      leading: img != null && img.isNotEmpty
          ? Image.network(img, width: 50, height: 50)
          : const Icon(Icons.article),
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      onTap: () => _openUrl(link),
    );
  }

  void _onBottomItemTapped(int index) {
    setState(() => _selectedIndexBottom = index);

    // Si eligen otra pestaña, volvemos al Home.
    if (index != 0) {
      // OPCIONAL: si en MyHomePageState agregas un método público setTab(int i),
      // puedes seleccionar la pestaña al volver:
      //
      // final homeState = context.findAncestorStateOfType<MyHomePageState>();
      // if (homeState != null) {
      //   homeState.setTab(index); // <- crea este método público en tu Home si lo deseas
      // }

      Navigator.of(context).pop(); // regresamos al Home
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
              : const Center(
                  child: Text(
                    'Busca equipos o noticias',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
      // 👇 Barra inferior consistente con el Home
      bottomNavigationBar: BottomNavigationWidget(
        selectedIndex: _selectedIndexBottom,
        onItemTapped: _onBottomItemTapped,
      ),
    );
  }
}
