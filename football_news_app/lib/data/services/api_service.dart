// lib/data/services/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:football_news_app/app/app_const.dart';
import 'package:football_news_app/data/models/article.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class ApiService {
  // Usamos la base protegida y los headers con X-App-Key
  static const String _base = AppConst.protectedApiBase;
  static const Duration _timeout = Duration(seconds: 20);

  Map<String, String> get _headers => AppConst.headers();


  Future<http.Response> _get(String path, {Map<String, String>? query}) {
    final uri = Uri.parse('$_base$path').replace(queryParameters: query);
    return http.get(uri, headers: _headers).timeout(_timeout);
  }

  // Parsea la respuesta estándar { b_Activo, responseMessage, lstResponseBody }
  T _parseEnvelope<T>(http.Response resp, T Function(dynamic body) mapper) {
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}');
    }
    final jsonResp = jsonDecode(resp.body) as Map<String, dynamic>;
    final ok = jsonResp['b_Activo'] == true;
    if (!ok) {
      final msg = (jsonResp['responseMessage'] ?? 'request failed').toString();
      throw Exception(msg);
    }
    return mapper(jsonResp['lstResponseBody']);
  }

  // -------- Endpoints --------


  Future<List<Article>> fetchInitialArticles() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final resp = await _get('/all-articles');
      final List<Article> articles = _parseEnvelope(resp, (body) {
        final list = (body as List<dynamic>);
        return list.map((e) => Article.fromJson(e as Map<String, dynamic>)).toList();
      });

      // Cachea
      prefs.setString('initialArticles', jsonEncode(articles));
      return articles;
    } catch (e, st) {
      debugPrint('fetchInitialArticles ERR: $e\n$st');
      // fallback a cache
      final cached = prefs.getString('initialArticles');
      if (cached != null) {
        final list = (jsonDecode(cached) as List<dynamic>)
            .map((e) => Article.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }
      rethrow;
    }
  }

  Future<List<Article>> fetchAllArticles() async {
    final resp = await _get('/all-articles');
    final List<Article> articles = _parseEnvelope(resp, (body) {
      final list = (body as List<dynamic>);
      return list.map((e) => Article.fromJson(e as Map<String, dynamic>)).toList();
    });

    
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('initialArticles', jsonEncode(articles));
    return articles;
  }

  Future<List<String>> fetchCategories() async {
    final resp = await _get('/categories');
    return _parseEnvelope(resp, (body) {
      final list = (body as List<dynamic>);
      return List<String>.from(list.map((e) => e.toString()));
    });
  }

  Future<List<Map<String, dynamic>>> searchTeams(String query) async {
    final resp = await _get('/search/equipos', query: {'q': query});
    return _parseEnvelope(resp, (body) {
      final list = (body as List<dynamic>);
      return list.map((e) => e as Map<String, dynamic>).toList();
    });
  }

  Future<List<Map<String, dynamic>>> searchNews(String query) async {
    final resp = await _get('/search/noticias', query: {'q': query});
    return _parseEnvelope(resp, (body) {
      final list = (body as List<dynamic>);
      return list.map((e) => e as Map<String, dynamic>).toList();
    });
  }

  Future<List<Article>> getCachedArticles({int limit = 10}) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('initialArticles');
    if (data == null) return [];

    final list = (jsonDecode(data) as List<dynamic>)
        .map((e) => Article.fromJson(e as Map<String, dynamic>))
        .toList();

    if (limit > 0 && list.length > limit) {
      return list.take(limit).toList();
    }
    return list;
  }
}
