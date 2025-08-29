// article.dart
class Article {
  final String title;
  final String preview;
  final String imageUrl;
  final String source;
  final int publishedTime;            // lo dejamos por compatibilidad
  final String imageUrlPublished;
  final String videoLink;
  final String publishedTimeText;     // ✅ NUEVO

  Article({
    required this.title,
    required this.preview,
    required this.imageUrl,
    required this.source,
    required this.publishedTime,
    required this.imageUrlPublished,
    required this.videoLink,
    required this.publishedTimeText,  // ✅ NUEVO
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: (json['title'] ?? '').toString(),
      preview: (json['preview'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
      // Si viene null, lo dejamos en 0. No lo usaremos para mostrar.
      publishedTime: json['publishedTime'] is int
          ? json['publishedTime'] as int
          : int.tryParse('${json['publishedTime'] ?? 0}') ?? 0,
      imageUrlPublished: (json['imageUrlPublished'] ?? '').toString(),
      videoLink: (json['videoLink'] ?? '').toString(),
      publishedTimeText: (json['publishedTimeText'] ?? '').toString(), // ✅ NUEVO
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'preview': preview,
      'imageUrl': imageUrl,
      'source': source,
      'publishedTime': publishedTime,
      'imageUrlPublished': imageUrlPublished,
      'videoLink': videoLink,
      'publishedTimeText': publishedTimeText, // ✅ NUEVO
    };
  }
}
