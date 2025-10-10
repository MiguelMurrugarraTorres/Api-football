import 'package:flutter/material.dart';
import 'package:football_news_app/data/models/match.dart';
import 'package:football_news_app/features/matches/widgets/status_kind.dart';
import 'package:football_news_app/features/matches/widgets/status_pill.dart';
import 'package:football_news_app/features/matches/widgets/team_row.dart';
import 'package:football_news_app/features/webview/pages/in_app_webview_page.dart';
import 'package:football_news_app/main.dart';

class MatchCard extends StatelessWidget {
  final MatchItem item;
  final StatusDisplay statusDisplay;

  const MatchCard({super.key, required this.item, required this.statusDisplay});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    String scoreText(int? v) => v?.toString() ?? '-';

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final raw = item.href.trim();
          if (raw.isEmpty) return;
          final url = (raw.startsWith('http')) ? raw : 'https://$raw';
          final title = '${item.homeName} vs ${item.awayName}';

          final homeState = homeKey.currentState;
          if (homeState != null) {
            homeState.openWebView(url, title: title);
            return;
          }
          final uri = Uri.tryParse(url);
          if (uri != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => InAppWebViewPage(uri: uri, title: title),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TeamRow(name: item.homeName, logo: item.homeLogo),
                    const SizedBox(height: 10),
                    TeamRow(name: item.awayName, logo: item.awayLogo),
                  ],
                ),
              ),
              SizedBox(
                width: 60,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${scoreText(item.homeScore)}',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('${scoreText(item.awayScore)}',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
              SizedBox(
                width: 84,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: StatusPill(
                    text: statusDisplay.text,
                    kind: statusDisplay.kind,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
