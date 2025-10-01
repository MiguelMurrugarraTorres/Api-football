import 'package:flutter/material.dart';
import 'package:football_news_app/data/services/api_service.dart';

class BottomNavigationWidget extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  BottomNavigationWidget({
    required this.selectedIndex,
    required this.onItemTapped,
  });

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

      // ✅ Si hay menos de 2 elementos, agregar una categoría extra
      if (categories.length < 2) {
        categories.add("Noticias"); // Categoría extra para evitar el error
      }
    });
  } catch (error) {
    print('Error fetching categories: $error');

    // ✅ Si hay error, asegurar que haya al menos 2 categorías
    setState(() {
      if (categories.length < 2) {
        categories = ['Inicio', 'Noticias'];
      }
    });
  }
}


  // ✅ Mantiene los íconos personalizados
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
      case 'Apuestas':
        return Icons.currency_bitcoin_outlined;
      default:
        return Icons.home;
    }
  }
@override
Widget build(BuildContext context) {
  if (categories.length < 2) {
    return const Center(child: CircularProgressIndicator()); // ✅ Mostrar indicador de carga temporalmente
  }

  return BottomNavigationBar(
    type: BottomNavigationBarType.fixed, // 👈 evita shifting: muestra todas las labels
    showSelectedLabels: true,    // 👈 muestra la categoría también en seleccionados
    showUnselectedLabels: true,  // 👈 muestra la categoría también en no seleccionados
    items: categories.map((category) {
      return BottomNavigationBarItem(
        icon: Icon(_getCategoryIcon(category)),
        label: category,
      );
    }).toList(),
    currentIndex: widget.selectedIndex,
    selectedItemColor: Colors.black,
    unselectedItemColor: Colors.grey,
    onTap: widget.onItemTapped,
  );
}

}