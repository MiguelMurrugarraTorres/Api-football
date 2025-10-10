// lib/features/home/pages/home_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:football_news_app/data/models/article.dart';
import 'package:football_news_app/data/services/api_service.dart';
import 'package:football_news_app/features/articles/pages/all_articles_screen.dart';
import 'package:football_news_app/features/articles/pages/search_screen.dart';
import 'package:football_news_app/features/home/widgets/article_card_widget.dart';
import 'package:football_news_app/features/home/widgets/bottom_navigation_widget.dart';
import 'package:football_news_app/features/home/widgets/first_article_widget.dart';
import 'package:football_news_app/shared/widgets/extensions/under_construction.dart';

import 'package:football_news_app/features/home/models/story_item.dart';
import 'package:football_news_app/features/home/services/stories_service.dart';
import 'package:football_news_app/features/home/widgets/stories_button.dart';
import 'package:football_news_app/features/home/pages/story_viewer_page.dart';

/// GlobalKey para abrir el WebView del Home desde PushService
final GlobalKey<MyHomePageState> homeKey = GlobalKey<MyHomePageState>();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<HomePage> {
  final ApiService apiService = ApiService();

  List<Article> articles = [];
  List<Article> cachedArticles = [];
  bool isLoading = false;

  int _selectedIndex = 0;

  // WebView integrado
  String? _webUrl;
  String? _webTitle;
  WebViewController? _inAppWebController;

  List<String> categories = ['Inicio'];
  String? _wipCategory;

  // STORIES
  final StoriesService _storiesService = StoriesService();
  List<StoryItem> _stories = [];
  bool _storiesLoading = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _loadCachedArticles();
    if (!mounted) return;

    await _fetchAllArticles();
    if (!mounted) return;

    await _fetchCategories();
    if (!mounted) return;

    await _loadStories();
  }

  Future<void> _loadCachedArticles() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('initialArticles');
    if (!mounted) return;
    if (cachedData != null) {
      final List<Article> cached = (jsonDecode(cachedData) as List)
          .map((data) => Article.fromJson(data))
          .toList();
      setState(() => articles = cached);
    }
  }

  Future<void> _fetchAllArticles() async {
    setState(() => isLoading = true);
    try {
      final fetched = await apiService.fetchAllArticles();
      if (!mounted) return;
      setState(() {
        cachedArticles = fetched;
        articles = fetched;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching all articles: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final fetchedCategories = await apiService.fetchCategories();
      if (!mounted) return;
      setState(() => categories = ['Inicio', ...fetchedCategories]);
    } catch (error) {
      debugPrint('Error fetching categories: $error');
    }
  }

  Future<void> _loadStories() async {
    setState(() => _storiesLoading = true);
    try {
      final pages = await _storiesService.fetchStories();
      final stories = <StoryItem>[];
      for (final m in pages) {
        final image = (m['image_url'] ?? '').toString();
        final title = (m['title'] ?? '').toString();
        final share = (m['share_url'] ?? '').toString();
        final provider = (m['provider'] != null)
            ? (m['provider']['name'] ?? '').toString()
            : '';
        if (image.isNotEmpty && share.isNotEmpty && title.isNotEmpty) {
          stories.add(StoryItem(
            title: title,
            providerName: provider,
            imageUrl: image,
            shareUrl: share,
          ));
        }
      }
      if (!mounted) return;
      setState(() {
        _stories = stories.take(12).toList();
        _storiesLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading stories: $e');
      if (!mounted) return;
      setState(() => _storiesLoading = false);
    }
  }

  // ===== NAV
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
    if (!mounted) return;
    setState(() {
      _webUrl = url;
      _webTitle = title;
    });
  }

  void _openStoriesViewer() {
    if (_stories.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => StoryViewerPage(
          stories: _stories,
          onOpenArticle: (url, title) => openWebView(url, title: title),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayed =
        articles.length > 7 ? articles.take(7).toList() : articles;

    final String appBarTitle =
        _webUrl != null ? (_webTitle ?? 'PREMIERFOOTBALL') : 'PREMIERFOOTBALL';

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
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
                    if (!mounted) return;
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
                  onRefresh: () async {
                    await _fetchAllArticles();
                    await _loadStories();
                  },
                  child: ListView.builder(
                    itemCount: (displayed.isEmpty ? 1 : displayed.length + 1) + 1,
                    itemBuilder: (context, index) {
                      // 0 → botón Stories
                      if (index == 0) {
                        return StoriesButton(
                          loading: _storiesLoading,
                          onTap: _openStoriesViewer,
                        );
                      }

                      final listIndex = index - 1;

                      if (displayed.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text('No articles available.'),
                          ),
                        );
                      } else if (listIndex == 0) {
                        return FirstArticleWidget(article: displayed[listIndex]);
                      } else if (listIndex == displayed.length) {
                        return Center(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AllArticlesScreen(
                                    articles: cachedArticles.isNotEmpty ? cachedArticles : articles,
                                  ),
                                ),
                              );
                            },
                            child: const Text('Ver más'),
                          ),
                        );
                      } else {
                        return ArticleCardWidget(
                          article: displayed[listIndex],
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

          // 2) Placeholder
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
