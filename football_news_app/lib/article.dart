class Article {
  final String title;
  final String preview;
  final String imageUrl;
  final String source;
  final int publishedTime; // Cambiado a int
  final String imageUrlPublished;
  final String videoLink;

  Article({
    required this.title,
    required this.preview,
    required this.imageUrl,
    required this.source,
    required this.publishedTime,
    required this.imageUrlPublished,
    required this.videoLink,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'],
      preview: json['preview'],
      imageUrl: json['imageUrl'],
      source: json['source'],
      publishedTime: json['publishedTime'],
      imageUrlPublished: json['imageUrlPublished'],
      videoLink: json['videoLink'],
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
    };
  }
}
