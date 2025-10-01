import 'package:flutter/material.dart';

class UnderConstruction extends StatelessWidget {
  final String? label;
  final VoidCallback? onGoHome;

  const UnderConstruction({super.key, this.label, this.onGoHome});

  @override
  Widget build(BuildContext context) {
    final section = (label == null || label!.toLowerCase() == 'inicio')
        ? 'Sección en construcción'
        : '“$label” en construcción';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              section,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Estamos trabajando para traer esta sección muy pronto.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onGoHome ?? () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.home),
              label: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}
