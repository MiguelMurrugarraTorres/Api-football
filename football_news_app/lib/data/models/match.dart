// lib/data/models/match.dart
class MatchItem {
  final String matchSlug;
  final String href;

  final String compName;
  final String compSlug;
  final String roundText;

  /// Puede venir ISO completo en la API actual
  final String dateKey;      // ej. "2025-10-09T00:00:00.000Z" o "YYYY-MM-DD"
  final String kickoffUtc;   // ISO (preferente) o "HH:mm"

  final String homeName;
  final String awayName;
  final String homeLogo;
  final String awayLogo;

  final int? homeScore;
  final int? awayScore;

  /// Estado corto o código
  final String status;

  /// Texto amigable. Puede venir vacío o null (→ lo tratamos como suspendido si score 0-0)
  final String statusText;

  /// NUEVO: si está en vivo
  final String? liveMinuteText; // ej. "83'"
  final int? liveMinute;        // ej. 83
  final String? period;         // ej. "1H", "2H", "HT", etc.

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
    this.liveMinuteText,
    this.liveMinute,
    this.period,
  });

  factory MatchItem.fromJson(Map<String, dynamic> json) {
    int? _toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    String _str(dynamic v) => (v ?? '').toString();

    return MatchItem(
      matchSlug: _str(json['match_slug']),
      href: _str(json['href']),
      compName: _str(json['comp_name']),
      compSlug: _str(json['comp_slug']),
      roundText: _str(json['round_text']),
      dateKey: _str(json['date_key']),
      kickoffUtc: _str(json['kickoff_utc']),
      homeName: _str(json['home_name']),
      awayName: _str(json['away_name']),
      homeLogo: _str(json['home_logo']),
      awayLogo: _str(json['away_logo']),
      homeScore: _toInt(json['home_score']),
      awayScore: _toInt(json['away_score']),
      status: _str(json['status']),
      statusText: _str(json['status_text']),
      liveMinuteText: json['live_minute_text']?.toString(),
      liveMinute: _toInt(json['live_minute']),
      period: json['period']?.toString(),
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
        'live_minute_text': liveMinuteText,
        'live_minute': liveMinute,
        'period': period,
      };
}
