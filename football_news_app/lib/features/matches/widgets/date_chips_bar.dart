import 'package:flutter/material.dart';

class DateChipsBar<T> extends StatelessWidget {
  final List<T> chips;
  final T selected;
  final ValueChanged<T> onTap;
  final String Function(T)? labelOf;

  const DateChipsBar({
    super.key,
    required this.chips,
    required this.selected,
    required this.onTap,
    this.labelOf,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = chips[i];
          final isSel = c == selected;
          final label = labelOf != null ? labelOf!(c) : c.toString();

          return ChoiceChip(
            label: Text(
              label,
              style: TextStyle(
                color: isSel ? scheme.onPrimaryContainer : null,
                fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            selected: isSel,
            onSelected: (_) => onTap(c),
            selectedColor: scheme.primaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          );
        },
      ),
    );
  }
}
