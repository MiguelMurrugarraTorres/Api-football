import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:football_news_app/app/app_const.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';



class AuthService {
  static const _prefsKeyUserId = 'auth_user_id';
  static const _prefsKeyExtId  = 'auth_external_id';
  static const _prefsKeyName   = 'auth_display_name';

  /// Devuelve el `userId` si ya existe en prefs, sino hace auth anónima en el backend.
  Future<int?> ensureAnonUser({String? displayName}) async {
    final prefs = await SharedPreferences.getInstance();

    // 1) Si ya existe userId almacenado, lo devolvemos
    final storedUserId = prefs.getInt(_prefsKeyUserId);
    if (storedUserId != null && storedUserId > 0) {
      return storedUserId;
    }

    // 2) Genera o lee externalId estable (persistente)
    var externalId = prefs.getString(_prefsKeyExtId);
    externalId ??= _generateExternalId();
    await prefs.setString(_prefsKeyExtId, externalId);
    if (displayName != null && displayName.trim().isNotEmpty) {
      await prefs.setString(_prefsKeyName, displayName.trim());
    }

    try {
      final resp = await http
          .post(
            Uri.parse('${AppConst.protectedApiBase}/auth/anon'),
            headers: AppConst.headers(),
            body: jsonEncode({
              'externalId': externalId,
              'displayName': displayName ?? prefs.getString(_prefsKeyName),
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (resp.statusCode != 200) {
        debugPrint('[AuthService] anon http=${resp.statusCode} body=${resp.body}');
        return null;
      }

      final map = jsonDecode(resp.body) as Map<String, dynamic>;
      final ok  = map['b_Activo'] == true;
      if (!ok) {
        debugPrint('[AuthService] anon server msg=${map['responseMessage']}');
        return null;
      }

      final list = (map['lstResponseBody'] as List?) ?? const [];
      if (list.isEmpty) return null;

      final userId = (list.first as Map)['userId'] as int?;
      if (userId != null && userId > 0) {
        await prefs.setInt(_prefsKeyUserId, userId);
        return userId;
      }
    } catch (e, st) {
      debugPrint('[AuthService] anon failed: $e\n$st');
    }
    return null;
  }

  Future<int?> getStoredUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefsKeyUserId);
  }

  Future<String?> getExternalId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKeyExtId);
  }

  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyUserId);
    await prefs.remove(_prefsKeyExtId);
    await prefs.remove(_prefsKeyName);
  }

  // --- util simple para "uuid-ish" sin dependencia extra
  String _generateExternalId() {
    final rnd = Random.secure();
    String hex(int bytes) =>
        List<int>.generate(bytes, (_) => rnd.nextInt(256))
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();
    // 8-4-4-4-12
    return '${hex(4)}-${hex(2)}-${hex(2)}-${hex(2)}-${hex(6)}';
  }
}
