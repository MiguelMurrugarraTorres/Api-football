import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'article.dart';

class ApiService {
  static const String baseUrl = 'https://pidelope.app/api';

  Future<List<Article>> fetchInitialArticles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      final response = await http.get(Uri.parse('$baseUrl/initial-articles'));

      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);

        if (jsonResponse['b_Activo']) {
          List<dynamic> body = jsonResponse['lstResponseBody'];
          List<Article> articles =
              body.map((dynamic item) => Article.fromJson(item)).toList();
          // Guardar en caché
          prefs.setString('initialArticles', jsonEncode(articles));
          return articles;
        } else {
          throw Exception(
              'Failed to load initial articles: ${jsonResponse['responseMessage']}');
        }
      } else {
        throw Exception('Failed to load initial articles');
      }
    } catch (error) {
      print('Error fetching initial articles: $error');
      // Cargar desde caché
      String? cachedData = prefs.getString('initialArticles');
      if (cachedData != null) {
        List<Article> cachedArticles = (jsonDecode(cachedData) as List)
            .map((data) => Article.fromJson(data))
            .toList();
        return cachedArticles;
      } else {
        throw Exception('No cached data available');
      }
    }
  }

  Future<List<Article>> fetchAllArticles() async {
    final response = await http.get(Uri.parse('$baseUrl/all-articles'));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      if (jsonResponse['b_Activo']) {
        List<dynamic> body = jsonResponse['lstResponseBody'];
        List<Article> articles =
            body.map((dynamic item) => Article.fromJson(item)).toList();
        return articles;
      } else {
        throw Exception(
            'Failed to load all articles: ${jsonResponse['responseMessage']}');
      }
    } else {
      throw Exception('Failed to load all articles');
    }
  }

  Future<List<String>> fetchCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      if (jsonResponse['b_Activo']) {
        List<dynamic> body = jsonResponse['lstResponseBody'];
        List<String> categories = List<String>.from(body);
        return categories;
      } else {
        throw Exception(
            'Failed to load categories: ${jsonResponse['responseMessage']}');
      }
    } else {
      throw Exception('Failed to load categories');
    }
  }
}
