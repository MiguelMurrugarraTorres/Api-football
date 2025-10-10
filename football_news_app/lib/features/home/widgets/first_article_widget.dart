import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:football_news_app/data/models/article.dart';
import 'package:football_news_app/features/webview/pages/in_app_webview_page.dart';
import 'package:football_news_app/main.dart';

/// PNG transparente 1x1 para el fade-in
final Uint8List _kTransparentImage = Uint8List.fromList([
  0x89,0x50,0x4E,0x47,0x0D,0x0A,0x1A,0x0A,0x00,0x00,0x00,0x0D,0x49,0x48,0x44,0x52,0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x08,0x06,0x00,0x00,0x00,0x1F,0x15,0xC4,0x89,0x00,0x00,0x00,0x0A,0x49,0x44,0x41,0x54,0x78,0x9C,0x63,0x00,0x01,0x00,0x00,0x05,0x00,0x01,0x0D,0x0A,0x2D,0xB4,0x00,0x00,0x00,0x00,0x49,0x45,0x4E,0x44,0xAE,0x42,0x60,0x82
]);

String _normalizeUrl(String link) {
  final l = link.trim();
  if (l.isEmpty) return '';
  return (l.startsWith('http://') || l.startsWith('https://')) ? l : 'https://$l';
}

class FirstArticleWidget extends StatelessWidget {
  final Article article;

  const FirstArticleWidget({super.key, required this.article});

  bool get _isTappable => article.videoLink.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: scheme.surface,
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _isTappable ? () => _launchURL(context, article.videoLink) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Etiqueta "Top News" con colores del tema
            const TopNewsLabel(),

            if (article.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: FadeInImage.memoryNetwork(
                    placeholder: _kTransparentImage,
                    image: article.imageUrl,
                    fit: BoxFit.cover,
                    imageErrorBuilder: (_, __, ___) => Container(color: scheme.surfaceVariant),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    article.title,
                    style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    semanticsLabel: article.title,
                  ),
                  const SizedBox(height: 8),

                  // Preview
                  if (article.preview.isNotEmpty) ...[
                    Text(
                      article.preview,
                      style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Footer
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
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 12, right: 12, bottom: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.whatshot, color: scheme.onPrimaryContainer, size: 18),
              const SizedBox(width: 8),
              Text(
                'Top News',
                style: text.labelMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ArticleFooter extends StatelessWidget {
  final Article article;

  const ArticleFooter({super.key, required this.article});

  String _friendlyTime() {
    if (article.publishedTimeText.isNotEmpty) return article.publishedTimeText;

    final t = article.publishedTime;
    if (t > 0) {
      final now = DateTime.now();
      DateTime? dt;
      if (t > 1000000000000) {
        dt = DateTime.fromMillisecondsSinceEpoch(t); // ms
      } else if (t > 1000000000) {
        dt = DateTime.fromMillisecondsSinceEpoch(t * 1000); // s
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
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Row(
      children: [
        // Logo fuente
        if (article.imageUrlPublished.isNotEmpty)
          ClipOval(
            child: Image.network(
              article.imageUrlPublished,
              width: 20,
              height: 20,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _dot(scheme),
            ),
          )
        else
          _dot(scheme),

        const SizedBox(width: 8),

        // Nombre fuente
        Flexible(
          child: Text(
            article.source,
            style: text.labelLarge,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),

        // Tiempo
        Text(
          _friendlyTime(),
          style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),

        const Spacer(),

        // CTA
        if (article.videoLink.isNotEmpty)
          TextButton(
            onPressed: () {
              final parent = context.findAncestorWidgetOfExactType<FirstArticleWidget>();
              parent?._launchURL(context, article.videoLink);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              foregroundColor: scheme.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            child: const Text('Ver video', style: TextStyle(fontSize: 12)),
          ),
      ],
    );
  }

  Widget _dot(ColorScheme scheme) => SizedBox(
        width: 20,
        height: 20,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceVariant,
            shape: BoxShape.circle,
          ),
        ),
      );
}
