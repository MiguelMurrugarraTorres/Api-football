// lib/data/services/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:football_news_app/app/app_const.dart';
import 'package:football_news_app/data/models/article.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ====== Config ======
  static const String _base = AppConst.protectedApiBase;
  static const Duration _timeout = Duration(seconds: 20);

  static const _kCacheArticles = 'initialArticles';
  static const _kCacheMatchesPrefix = 'matches:'; // matches:YYYY-MM-DD
  static const _kCacheTeamsAll = 'teams:all';
  static const _kCacheTeamsByLetterPrefix = 'teams:letter:'; // teams:letter:a

  Map<String, String> get _headers => AppConst.headers();

  // ====== Low-level HTTP ======
  Future<http.Response> _get(String path, {Map<String, String>? query}) {
    final uri = Uri.parse('$_base$path').replace(queryParameters: query);
    return http.get(uri, headers: _headers).timeout(_timeout);
  }

  // Envuelve el parseo de la respuesta estándar:
  // { b_Activo, responseMessage, lstResponseBody }
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

  // Parse en background para listas de artículos
  static List<Article> _mapArticles(dynamic body) {
    final list = (body as List<dynamic>);
    return list
        .map((e) => Article.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ====== ARTÍCULOS ======
  Future<List<Article>> fetchInitialArticles() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final resp = await _get('/all-articles');
      final List<Article> articles =
          await compute(_mapArticles, _parseEnvelope(resp, (b) => b));

      // Cache persistente (JSON serializado)
      try {
        final encoded = jsonEncode(articles.map((a) => a.toJson()).toList());
        await prefs.setString(_kCacheArticles, encoded);
      } catch (_) {
        // Si falla el toJson (modelos antiguos), no bloqueamos el flujo
      }
      return articles;
    } catch (e, st) {
      debugPrint('fetchInitialArticles ERR: $e\n$st');
      // Fallback al caché
      final cached = prefs.getString(_kCacheArticles);
      if (cached != null) {
        try {
          final list = (jsonDecode(cached) as List<dynamic>)
              .map((e) => Article.fromJson(e as Map<String, dynamic>))
              .toList();
          return list;
        } catch (_) {
          // Si el caché es viejo o incompatible, lo ignoramos.
        }
      }
      rethrow;
    }
  }

  Future<List<Article>> fetchAllArticles() async {
    final resp = await _get('/all-articles');
    final List<Article> articles =
        await compute(_mapArticles, _parseEnvelope(resp, (b) => b));

    // Actualiza caché
    final prefs = await SharedPreferences.getInstance();
    try {
      final encoded = jsonEncode(articles.map((a) => a.toJson()).toList());
      await prefs.setString(_kCacheArticles, encoded);
    } catch (_) {}
    return articles;
  }

  Future<List<Article>> getCachedArticles({int limit = 10}) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_kCacheArticles);
    if (data == null) return [];
    try {
      final list = (jsonDecode(data) as List<dynamic>)
          .map((e) => Article.fromJson(e as Map<String, dynamic>))
          .toList();
      if (limit > 0 && list.length > limit) {
        return list.take(limit).toList();
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> fetchCategories() async {
    final resp = await _get('/categories');
    return _parseEnvelope(resp, (body) {
      final list = (body as List<dynamic>);
      return List<String>.from(list.map((e) => e.toString()));
    });
  }

  Future<List<Map<String, dynamic>>> searchNews(String query) async {
    final resp = await _get('/search/noticias', query: {'q': query});
    return _parseEnvelope(resp, (body) {
      final list = (body as List<dynamic>);
      return list.map((e) => e as Map<String, dynamic>).toList();
    });
  }

  // ====== EQUIPOS ======
  Future<List<Map<String, dynamic>>> searchTeams(String query) async {
    final resp = await _get('/search/equipos', query: {'q': query});
    return _parseEnvelope(resp, (body) {
      final list = (body as List<dynamic>);
      return list.map((e) => e as Map<String, dynamic>).toList();
    });
  }

  /// Lista completa de equipos (puede ser pesada). Cachea localmente.
  Future<List<Map<String, dynamic>>> fetchTeamsAll() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final resp = await _get('/teams');
      final data = _parseEnvelope(resp, (body) {
        final list = (body as List<dynamic>);
        return list.map((e) => e as Map<String, dynamic>).toList();
      });
      // Cache
      await prefs.setString(_kCacheTeamsAll, jsonEncode(data));
      return data;
    } catch (e, st) {
      debugPrint('fetchTeamsAll ERR: $e\n$st');
      final cached = prefs.getString(_kCacheTeamsAll);
      if (cached != null) {
        try {
          final list = (jsonDecode(cached) as List<dynamic>)
              .map((e) => e as Map<String, dynamic>)
              .toList();
          return list;
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// Equipos por letra A–Z: GET /api/teams/by-letter?letter=a
  Future<List<Map<String, dynamic>>> fetchTeamsByLetter(String letter) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_kCacheTeamsByLetterPrefix$letter';
    try {
      final resp = await _get('/teams/by-letter', query: {'letter': letter});
      final data = _parseEnvelope(resp, (body) {
        final list = (body as List<dynamic>);
        return list.map((e) => e as Map<String, dynamic>).toList();
      });
      await prefs.setString(cacheKey, jsonEncode(data));
      return data;
    } catch (e, st) {
      debugPrint('fetchTeamsByLetter ERR: $e\n$st');
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        try {
          final list = (jsonDecode(cached) as List<dynamic>)
              .map((e) => e as Map<String, dynamic>)
              .toList();
          return list;
        } catch (_) {}
      }
      rethrow;
    }
  }

  // ====== PARTIDOS ======
  /// Partidos por fecha (YYYY-MM-DD). Si null, el backend puede asumir “hoy”.
  /// Cachea por día.
  Future<List<Map<String, dynamic>>> fetchMatches({String? date}) async {
    final prefs = await SharedPreferences.getInstance();
    final q = date != null ? {'date': date} : null;
    final cacheKey = '$_kCacheMatchesPrefix${date ?? 'today'}';

    try {
      final resp = await _get('/matches', query: q);
      final data = _parseEnvelope(resp, (body) {
        final list = (body as List<dynamic>);
        return list.map((e) => e as Map<String, dynamic>).toList();
      });
      await prefs.setString(cacheKey, jsonEncode(data));
      return data;
    } catch (e, st) {
      debugPrint('fetchMatches ERR: $e\n$st');
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        try {
          final list = (jsonDecode(cached) as List<dynamic>)
              .map((e) => e as Map<String, dynamic>)
              .toList();
          return list;
        } catch (_) {}
      }
      rethrow;
    }
  }


    // === TEAMS ===

  Future<List<Map<String, dynamic>>> fetchTeamsRaw() async {
    final resp = await _get('/teams');
    return _parseEnvelope(resp, (body) {
      final list = (body as List<dynamic>);
      return list.map((e) => e as Map<String, dynamic>).toList();
    });
  }

  Future<List<Map<String, dynamic>>> searchTeamsV2(String query) async {
    final resp = await _get('/teams/search', query: {'q': query});
    return _parseEnvelope(resp, (body) {
      final list = (body as List<dynamic>);
      return list.map((e) => e as Map<String, dynamic>).toList();
    });
  }

}
