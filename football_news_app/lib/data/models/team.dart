// lib/data/models/team.dart
class TeamItem {
  final int id;
  final String slug;
  final String displayName;
  final String? country;
  final String href;
  final String? logoUrl;

  const TeamItem({
    required this.id,
    required this.slug,
    required this.displayName,
    required this.country,
    required this.href,
    required this.logoUrl,
  });

  factory TeamItem.fromJson(Map<String, dynamic> json) => TeamItem(
        id: (json['id'] ?? 0) as int,
        slug: (json['slug'] ?? '').toString(),
        displayName: (json['display_name'] ?? '').toString(),
        country: (json['country'] as String?)?.toString(),
        href: (json['href'] ?? '').toString(),
        logoUrl: (json['logo_url'] as String?)?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'display_name': displayName,
        'country': country,
        'href': href,
        'logo_url': logoUrl,
      };
}
