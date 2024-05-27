import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:football_news_app/api_service.dart';
import 'package:football_news_app/article.dart';
import 'package:football_news_app/article_card_widget.dart';
import 'package:football_news_app/first_article_widget.dart';
import 'package:football_news_app/all_articles_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ApiService apiService = ApiService();
  List<Article> articles = [];
  List<Article> cachedArticles = [];
  bool isLoading = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    loadCachedArticles();
    fetchInitialArticles();
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
      List<Article> fetchedArticles = await apiService.fetchAllArticles();
      setState(() {
        cachedArticles = fetchedArticles;
      });
    } catch (error) {
      print('Error fetching all articles: $error');
    }
  }

  Future<void> refreshArticles() async {
    try {
      List<Article> fetchedArticles = await apiService.fetchAllArticles();
      setState(() {
        cachedArticles = fetchedArticles;
      });
      setState(() {
        articles = fetchedArticles.sublist(0, 7);
      });
    } catch (error) {
      print('Error refreshing articles: $error');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Aquí puedes manejar la navegación entre las categorías
      // Por ejemplo, puedes cambiar a la pantalla correspondiente basada en el índice seleccionado
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PREMIERFOOTBALL',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: refreshArticles,
              child: ListView.builder(
                itemCount: articles.isEmpty ? 1 : articles.length + 1,
                itemBuilder: (context, index) {
                  if (articles.isEmpty) {
                    return Center(child: Text('No articles available.'));
                  } else if (index == 0) {
                    return FirstArticleWidget(article: articles[index]);
                  } else if (index == articles.length) {
                    return Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AllArticlesScreen(articles: cachedArticles),
                            ),
                          );
                        },
                        child: Text('Ver más'),
                      ),
                    );
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
