// lib/data/models/match.dart
class MatchItem {
  final String matchSlug;
  final String href;

  final String compName;
  final String compSlug;
  final String roundText;

  final String dateKey; // YYYY-MM-DD
  final String kickoffUtc; // ISO o HH:mm UTC (depende de tu scraper)

  final String homeName;
  final String awayName;
  final String homeLogo;
  final String awayLogo;

  final int? homeScore;
  final int? awayScore;

  /// Ej.: "FT", "NS", "LIVE", etc. (código breve si lo manejas así)
  final String status;

  /// Ej.: "Final del partido", "En juego", "Por empezar"
  final String statusText;

  const MatchItem({
    required this.matchSlug,
    required this.href,
    required this.compName,
    required this.compSlug,
    required this.roundText,
    required this.dateKey,
    required this.kickoffUtc,
    required this.homeName,
    required this.awayName,
    required this.homeLogo,
    required this.awayLogo,
    required this.homeScore,
    required this.awayScore,
    required this.status,
    required this.statusText,
  });

  factory MatchItem.fromJson(Map<String, dynamic> json) {
    int? _toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    return MatchItem(
      matchSlug: (json['match_slug'] ?? '').toString(),
      href: (json['href'] ?? '').toString(),
      compName: (json['comp_name'] ?? '').toString(),
      compSlug: (json['comp_slug'] ?? '').toString(),
      roundText: (json['round_text'] ?? '').toString(),
      dateKey: (json['date_key'] ?? '').toString(),
      kickoffUtc: (json['kickoff_utc'] ?? '').toString(),
      homeName: (json['home_name'] ?? '').toString(),
      awayName: (json['away_name'] ?? '').toString(),
      homeLogo: (json['home_logo'] ?? '').toString(),
      awayLogo: (json['away_logo'] ?? '').toString(),
      homeScore: _toInt(json['home_score']),
      awayScore: _toInt(json['away_score']),
      status: (json['status'] ?? '').toString(),
      statusText: (json['status_text'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'match_slug': matchSlug,
        'href': href,
        'comp_name': compName,
        'comp_slug': compSlug,
        'round_text': roundText,
        'date_key': dateKey,
        'kickoff_utc': kickoffUtc,
        'home_name': homeName,
        'away_name': awayName,
        'home_logo': homeLogo,
        'away_logo': awayLogo,
        'home_score': homeScore,
        'away_score': awayScore,
        'status': status,
        'status_text': statusText,
      };
}
