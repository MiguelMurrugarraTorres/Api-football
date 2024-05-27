import 'package:flutter/material.dart';
import 'package:football_news_app/api_service.dart';
import 'article.dart';
import 'article_card_widget.dart';
import 'first_article_widget.dart';
import 'bottom_navigation_widget.dart';

class AllArticlesScreen extends StatefulWidget {
  final List<Article> articles;

  AllArticlesScreen({required this.articles});

  @override
  _AllArticlesScreenState createState() => _AllArticlesScreenState();
}

class _AllArticlesScreenState extends State<AllArticlesScreen> {
  ApiService apiService = ApiService();
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
    setState(() {
      isLoadingMore = true;
    });
    try {
      List<Article> fetchedArticles = await apiService.fetchAllArticles();
      setState(() {
        articles.addAll(fetchedArticles);
        currentLength = articles.length;
        isLoadingMore = false;
      });
    } catch (error) {
      print('Error loading more articles: $error');
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Aquí puedes manejar la navegación entre las categorías
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Articles'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (!isLoadingMore &&
              scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
            loadMoreArticles();
          }
          return true;
        },
        child: ListView.builder(
          itemCount: articles.length,
          itemBuilder: (context, index) {
            if (index == 0) {
              return FirstArticleWidget(article: articles[index]);
            } else {
              return ArticleCardWidget(article: articles[index]);
            }
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
