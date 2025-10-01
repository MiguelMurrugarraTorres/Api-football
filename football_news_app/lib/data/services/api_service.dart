import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article.dart';

class ApiService {
  static const String baseUrl = 'https://pidelope.app/api';

  Future<List<Article>> fetchInitialArticles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      final response = await http.get(Uri.parse('$baseUrl/all-articles'));

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
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['b_Activo']) {
        final body = jsonResponse['lstResponseBody'] as List<dynamic>;
        final articles = body.map((e) => Article.fromJson(e)).toList();

        // ✅ Guarda también en cache
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('initialArticles', jsonEncode(articles));

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

  Future<List<Map<String, dynamic>>> searchTeams(String query) async {
    final response =
        await http.get(Uri.parse('$baseUrl/search/equipos?q=$query'));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      if (jsonResponse['b_Activo']) {
        List<dynamic> body = jsonResponse['lstResponseBody'];
        return body
            .map((dynamic item) => item as Map<String, dynamic>)
            .toList();
      } else {
        throw Exception(
            'Failed to load teams: ${jsonResponse['responseMessage']}');
      }
    } else {
      throw Exception('Failed to load teams');
    }
  }

  Future<List<Map<String, dynamic>>> searchNews(String query) async {
    final response =
        await http.get(Uri.parse('$baseUrl/search/noticias?q=$query'));

    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      if (jsonResponse['b_Activo']) {
        List<dynamic> body = jsonResponse['lstResponseBody'];
        return body
            .map((dynamic item) => item as Map<String, dynamic>)
            .toList();
      } else {
        throw Exception(
            'Failed to load news: ${jsonResponse['responseMessage']}');
      }
    } else {
      throw Exception('Failed to load news');
    }
  }

  Future<List<Article>> getCachedArticles({int limit = 10}) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('initialArticles');
    if (data == null) return [];

    final List<dynamic> list = jsonDecode(data) as List<dynamic>;
    final articles = list.map((e) => Article.fromJson(e)).toList();

    if (limit > 0 && articles.length > limit) {
      return articles.take(limit).toList();
    }
    return articles;
  }
}
