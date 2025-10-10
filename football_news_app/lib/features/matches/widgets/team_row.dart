import 'package:flutter/material.dart';

class TeamRow extends StatelessWidget {
  final String name;
  final String logo;
  const TeamRow({super.key, required this.name, required this.logo});

  @override
  Widget build(BuildContext context) {
    final has = logo.isNotEmpty;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        ClipOval(
          child: has
              ? Image.network(
                  logo,
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(scheme),
                )
              : _placeholder(scheme),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _placeholder(ColorScheme scheme) => Container(
        width: 28,
        height: 28,
        color: scheme.surfaceVariant,
        child: Icon(Icons.shield_outlined, size: 16, color: scheme.onSurfaceVariant),
      );
}
