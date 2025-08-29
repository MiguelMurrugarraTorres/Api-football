import 'package:flutter/material.dart';
import 'article.dart';

class ArticleCardWidget extends StatelessWidget {
  final Article article;
  final Function(String) openWebView; // ✅ Recibe la función para abrir WebView

  ArticleCardWidget({
    required this.article,
    required this.openWebView, // ✅ Agregamos este parámetro
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
            onTap: () {
        if (article.videoLink.isNotEmpty) {
          openWebView(article.videoLink);
        }
      },
      child: Card(
        color: Colors.white,
        margin: const EdgeInsets.all(5),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      article.title,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (article.imageUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 15, top: 15, right: 5, bottom: 0),
                      child: SizedBox(
                        width: 75,
                        height: 72,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            article.imageUrl,
                            width: 72,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Row(
                  children: [
                    article.imageUrlPublished.isNotEmpty
                        ? ClipOval(
                            child: Image.network(article.imageUrlPublished,
                                width: 20, height: 20))
                        : Container(),
                    const SizedBox(width: 15),
                    Text(
                      article.source,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      article.publishedTimeText.isNotEmpty
                          ? article.publishedTimeText // ✅
                          : 'Hace ${article.publishedTime} h',
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                    article.videoLink.isNotEmpty
                        ? TextButton(
                            onPressed: () {
                              print(
                                  "[DEBUG] Abriendo URL desde el botón: ${article.videoLink}");
                              openWebView(article
                                  .videoLink); // ✅ Llama a la función pasada
                            },
                            child: const Text('Ver'),
                          )
                        : Container(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
