import 'package:flutter/material.dart';
import 'package:football_news_app/features/matches/widgets/status_kind.dart';

class StatusPill extends StatelessWidget {
  final String text;
  final StatusKind kind;

  const StatusPill({super.key, required this.text, required this.kind});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Color color;
    switch (kind) {
      case StatusKind.live:
        color = Colors.red; // acento para LIVE
        break;
      case StatusKind.suspended:
        color = scheme.error; // aviso
        break;
      default:
        color = scheme.onSurfaceVariant; // neutro
    }
    final isLive = kind == StatusKind.live;

    if (isLive) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      );
    }
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context)
          .textTheme
          .labelSmall
          ?.copyWith(color: color, fontWeight: FontWeight.w600),
    );
  }
}
