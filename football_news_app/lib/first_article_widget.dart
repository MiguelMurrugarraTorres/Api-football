import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:football_news_app/main.dart';
import 'article.dart';

class FirstArticleWidget extends StatelessWidget {
  final Article article;

  FirstArticleWidget({required this.article});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.all(10),
      child: InkWell(
        onTap: () {
          if (article.videoLink.isNotEmpty) {
            _launchURL(context, article.videoLink);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8.0, bottom: 8.0, top: 8.0),
              child: Row(
                children: [
                  Icon(Icons.whatshot, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Top News', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            article.imageUrl.isNotEmpty
                ? Image.network(article.imageUrl)
                : const SizedBox.shrink(),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      article.imageUrlPublished.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                article.imageUrlPublished,
                                width: 20,
                                height: 20,
                              ),
                            )
                          : const SizedBox.shrink(),
                      const SizedBox(width: 5),
                      Text(article.source),
                      const SizedBox(width: 10),
                      Text(
                        article.publishedTimeText.isNotEmpty
                            ? article.publishedTimeText
                            : 'Hace ${article.publishedTime} horas',
                      ),
                      article.videoLink.isNotEmpty
                          ? TextButton(
                              onPressed: () => _launchURL(context, article.videoLink),
                              child: const Text('Ver video', style: TextStyle(fontSize: 10)),
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchURL(BuildContext context, String url) {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enlace vacío')),
      );
      return;
    }

    // 1) Si estamos bajo MyHomePage (Home), usa su WebView en el IndexedStack
    final homeState = context.findAncestorStateOfType<MyHomePageState>();
    if (homeState != null) {
      homeState.openWebView(url);
      return;
    }

    // 2) Fallback: abre una WebView propia en esta ruta (funciona en AllArticlesScreen)
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL inválida')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          final controller = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..loadRequest(uri);
          return Scaffold(
            appBar: AppBar(title: const Text('')),
            body: SizedBox.expand( // 👈 asegura ocupar todo el espacio y que haga scroll
              child: WebViewWidget(controller: controller),
            ),
          );
        },
      ),
    );
  }
}
