import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'article.dart';

class ArticleCardWidget extends StatelessWidget {
  final Article article;

  ArticleCardWidget({required this.article});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.all(5),
      //elevation: 5,
      child: Padding(
        padding: EdgeInsets.all(2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text(
            //   article.preview,
            //   style: TextStyle(fontSize: 14),
            // ),
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
              padding: const EdgeInsets.only(
                left: 2,
              ),
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
                    '. Hace ${article.publishedTime} h',
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                  article.videoLink.isNotEmpty
                      ? TextButton(
                          style: ButtonStyle(),
                          onPressed: () {
                            _launchURL(context, article.videoLink);
                          },
                          child: Text('Ver'),
                        )
                      : Container(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchURL(BuildContext context, String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not launch $url'),
      ));
    }
  }
}
