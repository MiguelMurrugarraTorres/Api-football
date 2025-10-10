import 'package:flutter/material.dart';
import 'package:football_news_app/data/models/match.dart';
import 'package:football_news_app/features/matches/widgets/match_card.dart';
import 'package:football_news_app/features/matches/widgets/status_kind.dart';

class LeagueKey {
  final String name;
  final String round;
  final String logoUrl;
  const LeagueKey(this.name, this.round, this.logoUrl);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LeagueKey &&
          name == other.name &&
          round == other.round &&
          logoUrl == other.logoUrl);

  @override
  int get hashCode => Object.hash(name, round, logoUrl);
}

class LeagueSection extends StatelessWidget {
  final LeagueKey league;
  final List<MatchItem> items;
  final StatusDisplay Function(MatchItem) computeStatus;

  const LeagueSection({
    super.key,
    required this.league,
    required this.items,
    required this.computeStatus,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  blurRadius: 6,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                  color: Colors.black.withOpacity(0.06),
                ),
              ],
            ),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  league.logoUrl,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 36,
                    height: 36,
                    color: scheme.surfaceVariant,
                    child: Icon(Icons.emoji_events_outlined,
                        size: 20, color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
              title: Text(league.name, style: Theme.of(context).textTheme.titleMedium),
              subtitle: league.round.isNotEmpty
                  ? Text(
                      league.round,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    )
                  : null,
            ),
          ),
        ),
        ...items.map((m) => MatchCard(item: m, statusDisplay: computeStatus(m))),
        const SizedBox(height: 8),
      ],
    );
  }
}
