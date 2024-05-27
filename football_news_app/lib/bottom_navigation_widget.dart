import 'package:flutter/material.dart';
import 'package:football_news_app/api_service.dart';

class BottomNavigationWidget extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  BottomNavigationWidget(
      {required this.selectedIndex, required this.onItemTapped});

  @override
  _BottomNavigationWidgetState createState() => _BottomNavigationWidgetState();
}

class _BottomNavigationWidgetState extends State<BottomNavigationWidget> {
  ApiService apiService = ApiService();
  List<String> categories = ['Inicio'];

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      List<String> fetchedCategories = await apiService.fetchCategories();
      setState(() {
        categories = ['Inicio'] + fetchedCategories;
      });
    } catch (error) {
      print('Error fetching categories: $error');
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Partidos':
        return Icons.sports_soccer;
      case 'Equipos':
        return Icons.group;
      case 'Competiciones':
        return Icons.emoji_events;
      case 'TV':
        return Icons.tv;
      default:
        return Icons.home;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Aseguramos que haya al menos dos elementos en categories
    if (categories.length < 2) {
      return SizedBox
          .shrink(); // Devuelve un widget vacío hasta que tengamos suficientes elementos
    }
    return BottomNavigationBar(
      items: categories.map((category) {
        return BottomNavigationBarItem(
          icon: Icon(_getCategoryIcon(category)),
          label: category,
        );
      }).toList(),
      currentIndex: widget.selectedIndex,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black,
      selectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      unselectedLabelStyle: TextStyle(fontSize: 12),
      onTap: widget.onItemTapped,
    );
  }
}
