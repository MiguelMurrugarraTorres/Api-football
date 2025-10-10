import 'package:flutter/material.dart';

class BottomNavigationWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  /// Opcional: fuerza la pestaña seleccionada por nombre (ej. 'Partidos')
  final String? selectedLabel;

  const BottomNavigationWidget({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.selectedLabel,
  });

  // 🔒 Estático: estos son los módulos fijos
  static const _items = <_NavItem>[
    _NavItem(label: 'Inicio',        icon: Icons.home,                  route: '/home'),
    _NavItem(label: 'Partidos',      icon: Icons.sports_soccer,         route: '/matches'),
    _NavItem(label: 'Equipos',       icon: Icons.group,                 route: '/teams'),
    _NavItem(label: 'Competiciones', icon: Icons.emoji_events,          route: '/competitions'),
    _NavItem(label: 'Apuestas',      icon: Icons.currency_bitcoin_outlined, route: '/bets'),
  ];

  String _normalize(String s) => s.trim().toLowerCase();

  int _currentIndex() {
    if (selectedLabel != null) {
      final i = _items.indexWhere(
        (e) => _normalize(e.label) == _normalize(selectedLabel!),
      );
      if (i != -1) return i;
    }
    return selectedIndex.clamp(0, _items.length - 1);
  }

  void _handleTap(BuildContext context, int index) {
    final item = _items[index];
    final labelNorm = _normalize(item.label);

    // Permite que Home maneje su propio stack si lo necesita
    if (labelNorm == 'inicio') {
      onItemTapped(index);
    }

    // Navegación por rutas (reemplaza pantalla actual)
    Navigator.of(context).pushReplacementNamed(item.route);
  }

  @override
  Widget build(BuildContext context) {
    final curr = _currentIndex();
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
      // Línea sutil superior que respeta el tema
          Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
          BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: scheme.surface,
            selectedItemColor: scheme.primary,
            unselectedItemColor: scheme.onSurfaceVariant,
            selectedIconTheme: IconThemeData(color: scheme.primary),
            unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            showSelectedLabels: true,
            showUnselectedLabels: true,
            items: _items
                .map(
                  (e) => BottomNavigationBarItem(
                    icon: Icon(e.icon),
                    label: e.label,
                  ),
                )
                .toList(),
            currentIndex: curr,
            onTap: (i) => _handleTap(context, i),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  const _NavItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}
