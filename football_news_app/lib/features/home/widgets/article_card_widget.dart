import 'package:flutter/material.dart';
import 'package:football_news_app/data/models/article.dart';

class ArticleCardWidget extends StatelessWidget {
  final Article article;
  final void Function(String) openWebView; // callback simple

  const ArticleCardWidget({
    super.key,
    required this.article,
    required this.openWebView,
  });

  bool get _isTappable => article.videoLink.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: scheme.surface,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _isTappable ? () => openWebView(article.videoLink) : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título + miniatura
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Expanded(
                    child: Text(
                      article.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  // Miniatura (opcional)
                  if (article.imageUrl.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 96,
                      height: 80,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          article.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: scheme.surfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // Footer: fuente + tiempo + CTA
              Row(
                children: [
                  // Logo fuente
                  if (article.imageUrlPublished.isNotEmpty)
                    ClipOval(
                      child: Image.network(
                        article.imageUrlPublished,
                        width: 20,
                        height: 20,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            SizedBox(width: 20, height: 20, child: _dot(scheme)),
                      ),
                    )
                  else
                    SizedBox(width: 20, height: 20, child: _dot(scheme)),
                  const SizedBox(width: 8),

                  // Nombre fuente
                  Flexible(
                    child: Text(
                      article.source,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Tiempo
                  Text(
                    article.publishedTimeText.isNotEmpty
                        ? article.publishedTimeText
                        : 'Hace ${article.publishedTime} h',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),

                  const Spacer(),

                  // CTA
                  if (_isTappable)
                    TextButton(
                      onPressed: () => openWebView(article.videoLink),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        foregroundColor: scheme.primary,
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Ver'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(ColorScheme scheme) => Container(
        decoration: BoxDecoration(
          color: scheme.surfaceVariant,
          shape: BoxShape.circle,
        ),
      );
}
