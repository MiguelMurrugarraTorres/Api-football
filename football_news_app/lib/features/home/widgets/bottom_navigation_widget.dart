// lib/features/home/widgets/bottom_navigation_widget.dart
import 'package:flutter/material.dart';
import 'package:football_news_app/data/services/api_service.dart';

class BottomNavigationWidget extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const BottomNavigationWidget({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  State<BottomNavigationWidget> createState() => _BottomNavigationWidgetState();
}

class _BottomNavigationWidgetState extends State<BottomNavigationWidget> {
  final ApiService apiService = ApiService();
  List<String> categories = ['Inicio', 'Partidos', 'TV'];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  String _normalize(String text) => text.trim().toLowerCase();

  Future<void> _fetchCategories() async {
    try {
      final fetched = await apiService.fetchCategories();

      final base = ['Inicio', 'Partidos', 'TV'];
      final merged = <String>[];

      void addIfNotExist(String v) {
        if (v.isNotEmpty &&
            !merged.any((x) => _normalize(x) == _normalize(v))) {
          merged.add(v);
        }
      }

      for (final b in base) addIfNotExist(b);
      for (final f in fetched) addIfNotExist(f);

      setState(() {
        categories = merged;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      setState(() {
        if (categories.length < 2) {
          categories = ['Inicio', 'Noticias', 'TV'];
        }
        isLoading = false;
      });
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (_normalize(category)) {
      case 'inicio':
        return Icons.home;
      case 'partidos':
        return Icons.sports_soccer;
      case 'equipos':
        return Icons.group;
      case 'competiciones':
        return Icons.emoji_events;
      case 'apuestas':
        return Icons.currency_bitcoin_outlined;
      case 'tv':
        return Icons.tv;
      case 'noticias':
        return Icons.article_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: categories
          .map((category) => BottomNavigationBarItem(
                icon: Icon(_getCategoryIcon(category)),
                label: category,
              ))
          .toList(),
      currentIndex: widget.selectedIndex.clamp(0, categories.length - 1),
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        final label = categories[index].trim().toLowerCase();

        switch (label) {
          case 'partidos':
            Navigator.of(context).pushNamed('/matches');
            return;
          case 'equipos':
            Navigator.of(context).pushNamed('/teams');
            return;
          case 'apuestas':
            Navigator.of(context).pushNamed('/bets');
            return;
          case 'tv':
            Navigator.of(context).pushNamed('/tv');
            return;
          default:
            widget.onItemTapped(index);
        }
      },
    );
  }
}
