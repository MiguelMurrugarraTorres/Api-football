import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'article.dart';

class FirstArticleWidget extends StatelessWidget {
  final Article article;

  FirstArticleWidget({required this.article});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.all(10),
      //elevation: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 8.0),
            child: Row(
              children: [
                Icon(
                  Icons.whatshot,
                  color: Colors.red,
                ),
                SizedBox(width: 8),
                Text(
                  'Top News',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          article.imageUrl.isNotEmpty
              ? Image.network(article.imageUrl)
              : Container(),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                // Text(
                //   article.preview,
                //   style: TextStyle(fontSize: 16),
                // ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    article.imageUrlPublished.isNotEmpty
                        ? ClipOval(
                            child: Image.network(article.imageUrlPublished,
                                width: 20, height: 20))
                        : Container(),
                    const SizedBox(width: 5),
                    Text(article.source),
                    const SizedBox(width: 10),
                    Text('Hace ${article.publishedTime} horas'),
                    article.videoLink.isNotEmpty
                        ? TextButton(
                            onPressed: () {
                              _launchURL(context, article.videoLink);
                            },
                            child: Text('Ver video'),
                          )
                        : Container(), // Cambiado a formato de horas
                  ],
                ),
              ],
            ),
          ),
        ],
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
