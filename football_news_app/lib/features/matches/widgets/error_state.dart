import 'package:flutter/material.dart';

class ErrorState extends StatelessWidget {
  final String message;
  const ErrorState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(Icons.wifi_off, size: 56, color: scheme.onSurfaceVariant),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'No se pudieron cargar los partidos.\n$message',
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
