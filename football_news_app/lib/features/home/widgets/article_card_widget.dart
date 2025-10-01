import 'package:flutter/material.dart';
import 'package:football_news_app/data/models/article.dart';

class ArticleCardWidget extends StatelessWidget {
  final Article article;
  final void Function(String) openWebView; // callback simple (no cambia firma)

  const ArticleCardWidget({
    super.key,
    required this.article,
    required this.openWebView,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (article.videoLink.isNotEmpty) {
          openWebView(article.videoLink); // el título lo inyecta el padre
        }
      },
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.all(5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título + imagen
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      article.title,
                      textAlign: TextAlign.start,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (article.imageUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: SizedBox(
                        width: 80,
                        height: 72,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            article.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.grey.shade200),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Footer (fuente, tiempo, botón Ver)
              Row(
                children: [
                  if (article.imageUrlPublished.isNotEmpty)
                    ClipOval(
                      child: Image.network(
                        article.imageUrlPublished,
                        width: 20,
                        height: 20,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox(width: 20, height: 20),
                      ),
                    )
                  else
                    const SizedBox(width: 20, height: 20),
                  const SizedBox(width: 8),
                  Text(
                    article.source,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    article.publishedTimeText.isNotEmpty
                        ? article.publishedTimeText
                        : 'Hace ${article.publishedTime} h',
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                  const Spacer(),
                  if (article.videoLink.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        debugPrint("[DEBUG] Abriendo URL: ${article.videoLink}");
                        openWebView(article.videoLink); // el título lo inyecta el padre
                      },
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
}
