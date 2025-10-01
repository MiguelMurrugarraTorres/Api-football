import 'package:flutter/material.dart';
import 'package:football_news_app/data/models/article.dart';

// ✅ usamos tu pestaña webview fallback unificada
import 'package:football_news_app/features/webview/pages/in_app_webview_page.dart';

// ✅ para usar openWebView(...) del Home
import 'package:football_news_app/main.dart';

class FirstArticleWidget extends StatelessWidget {
  final Article article;

  const FirstArticleWidget({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (article.videoLink.isNotEmpty) {
            _launchURL(context, article.videoLink);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TopNewsLabel(),
            if (article.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  article.imageUrl,
                  fit: BoxFit.fill,
                  width: double.infinity,
                  height: 180,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.preview,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  ArticleFooter(article: article),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchURL(BuildContext context, String url) {
    final link = url.trim();
    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enlace vacío')),
      );
      return;
    }

    // Normaliza por si viniera sin esquema
    final normalized =
        (link.startsWith('http://') || link.startsWith('https://'))
            ? link
            : 'https://$link';

    // 1) Si estamos bajo MyHomePage, usa su pestaña WebView y pasa el título
    final homeState = context.findAncestorStateOfType<MyHomePageState>();
    if (homeState != null) {
      homeState.openWebView(normalized, title: article.title);
      return;
    }

    // 2) Fallback: pantalla propia con título
    final uri = Uri.tryParse(normalized);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL inválida')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InAppWebViewPage(uri: uri, title: article.title),
      ),
    );
  }
}

class TopNewsLabel extends StatelessWidget {
  const TopNewsLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 12, top: 12),
      child: Row(
        children: [
          Icon(Icons.whatshot, color: Colors.red),
          SizedBox(width: 8),
          Text('Top News', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class ArticleFooter extends StatelessWidget {
  final Article article;

  const ArticleFooter({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (article.imageUrlPublished.isNotEmpty)
          ClipOval(
            child: Image.network(
              article.imageUrlPublished,
              width: 20,
              height: 20,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ),
          ),
        if (article.imageUrlPublished.isNotEmpty) const SizedBox(width: 5),
        Text(article.source, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(width: 10),
        Text(
          article.publishedTimeText.isNotEmpty
              ? article.publishedTimeText
              : 'Hace ${article.publishedTime} horas',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const Spacer(),
        if (article.videoLink.isNotEmpty)
          TextButton(
            onPressed: () => _launchURL(context, article.videoLink),
            child: const Text('Ver video', style: TextStyle(fontSize: 10)),
          ),
      ],
    );
  }

  void _launchURL(BuildContext context, String url) {
    final parent = context.findAncestorWidgetOfExactType<FirstArticleWidget>();
    parent?._launchURL(context, url); // reusa el método del widget principal
  }
}
