import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String dateLabel;
  const EmptyState({super.key, required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(Icons.sports_soccer_outlined, size: 56, color: scheme.onSurfaceVariant),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'No hay partidos para $dateLabel.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
