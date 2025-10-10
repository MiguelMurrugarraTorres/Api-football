import 'package:flutter/material.dart';

enum MatchesFilterType { all, liveOnly }

Future<MatchesFilterType?> showMatchesFilterSheet(
  BuildContext context, {
  required MatchesFilterType current,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;

  return showModalBottomSheet<MatchesFilterType>(
    context: context,
    isScrollControlled: false,
    showDragHandle: true,
    backgroundColor: scheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      var selected = current;

      Widget sectionTitle(String text) => Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
            child: Text(
              text,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          );

      Widget option(String label, MatchesFilterType value) {
        return RadioListTile<MatchesFilterType>(
          value: value,
          groupValue: selected,
          onChanged: (v) {
            if (v != null) {
              selected = v;
              (ctx as Element).markNeedsBuild();
            }
          },
          title: Text(label),
          dense: true,
          activeColor: scheme.primary,
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        );
      }

      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Filtro',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 12),
              sectionTitle('Tipos de partidos'),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      option('En directo ahora', MatchesFilterType.liveOnly),
                      const Divider(height: 1),
                      option('Ver partidos', MatchesFilterType.all),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(ctx, MatchesFilterType.all),
                    icon: Icon(Icons.filter_alt_off_outlined, color: scheme.primary),
                    label: Text('Quitar filtro',
                        style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                ],
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, selected),
                  child: const Text('APLICAR'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
