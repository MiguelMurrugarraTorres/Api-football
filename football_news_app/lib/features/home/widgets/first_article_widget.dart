import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:football_news_app/data/models/article.dart';
import 'package:football_news_app/features/webview/pages/in_app_webview_page.dart';
import 'package:football_news_app/main.dart';

// PNG transparente 1x1 para efecto fade-in sin libs extra
final Uint8List _kTransparentImage = Uint8List.fromList(
  [
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82
  ],
);

String _normalizeUrl(String link) {
  final l = link.trim();
  if (l.isEmpty) return '';
  return (l.startsWith('http://') || l.startsWith('https://'))
      ? l
      : 'https://$l';
}

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
          // Si en el futuro agregas article.url, puedes hacer:
          // else if (article.url?.isNotEmpty == true) { _launchURL(context, article.url!); }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TopNewsLabel(),
            if (article.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: FadeInImage.memoryNetwork(
                    placeholder: _kTransparentImage,
                    image: article.imageUrl,
                    fit: BoxFit.cover,
                    imageErrorBuilder: (_, __, ___) => const SizedBox(),
                  ),
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
                    semanticsLabel: article.title,
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
    final normalized = _normalizeUrl(url);
    if (normalized.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enlace vacío')),
      );
      return;
    }

    // 1) Si estamos bajo MyHomePage, usar su pestaña WebView
    final homeState = context.findAncestorStateOfType<MyHomePageState>();
    if (homeState != null) {
      homeState.openWebView(normalized, title: article.title);
      return;
    }

    // 2) Fallback a pantalla propia
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

  String _friendlyTime() {
    if (article.publishedTimeText.isNotEmpty) return article.publishedTimeText;

    // Fallback básico: si publishedTime parece epoch en segundos o ms
    final t = article.publishedTime;
    if (t > 0) {
      final now = DateTime.now();
      DateTime? dt;
      if (t > 1000000000000) {
        // milisegundos
        dt = DateTime.fromMillisecondsSinceEpoch(t);
      } else if (t > 1000000000) {
        // segundos
        dt = DateTime.fromMillisecondsSinceEpoch(t * 1000);
      }
      if (dt != null) {
        final diff = now.difference(dt);
        if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
        if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
        return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      }
    }
    return 'Hace ${article.publishedTime} horas';
  }

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
        Flexible(
          child: Text(
            article.source,
            style: Theme.of(context).textTheme.labelSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          _friendlyTime(),
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
    // Reusa el método del widget principal (misma unidad de compilación, permite llamada a método privado)
    final parent = context.findAncestorWidgetOfExactType<FirstArticleWidget>();
    parent?._launchURL(context, url);
  }
}
