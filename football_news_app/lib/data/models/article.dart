// lib/data/models/article.dart
class Article {
  final String title;
  final String preview;
  final String imageUrl;
  final String source;
  final int publishedTime; // usado internamente (timestamp)
  final String imageUrlPublished;
  final String videoLink;
  final String publishedTimeText;

  const Article({
    required this.title,
    required this.preview,
    required this.imageUrl,
    required this.source,
    required this.publishedTime,
    required this.imageUrlPublished,
    required this.videoLink,
    required this.publishedTimeText,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: (json['title'] ?? '').toString(),
      preview: (json['preview'] ?? '').toString(),
      imageUrl: (json['imageUrlMax'] ?? json['imageUrl'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
      publishedTime: _parseInt(json['publishedTime']),
      imageUrlPublished: (json['imageUrlPublished'] ?? '').toString(),
      videoLink: (json['videoLink'] ?? '').toString(),
      publishedTimeText: (json['publishedTimeText'] ?? '').toString(),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'preview': preview,
      'imageUrlMax': imageUrl,
      'source': source,
      'publishedTime': publishedTime,
      'imageUrlPublished': imageUrlPublished,
      'videoLink': videoLink,
      'publishedTimeText': publishedTimeText,
    };
  }
}
