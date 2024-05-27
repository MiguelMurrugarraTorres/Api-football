import 'package:flutter/material.dart';
import 'package:football_news_app/article.dart';
import 'package:football_news_app/article_card_widget.dart';

class MoreArticlesPage extends StatelessWidget {
  final List<Article> articles;

  MoreArticlesPage({required this.articles});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Más Noticias'),
      ),
      body: ListView.builder(
        itemCount: articles.length,
        itemBuilder: (context, index) {
          return ArticleCardWidget(article: articles[index]);
        },
      ),
    );
  }
}
