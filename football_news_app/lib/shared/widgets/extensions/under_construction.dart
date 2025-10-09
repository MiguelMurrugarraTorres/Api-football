// lib/shared/widgets/extensions/under_construction.dart
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

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Center(
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
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.home),
                label: const Text('Volver al inicio'),
                onPressed: () {
                  // 🔹 Si se pasó una acción personalizada, la usamos.
                  if (onGoHome != null) {
                    onGoHome!();
                    return;
                  }

                  // 🔹 Si se puede volver atrás, volvemos.
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  } else {
                    // 🔹 Si no hay stack atrás (pushReplacement), redirigimos al home.
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/home',
                      (r) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
