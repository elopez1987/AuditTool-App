import 'dart:async';

import 'package:audit_tool/auth/session.dart';
import 'package:audit_tool/core/api_config.dart';
import 'package:audit_tool/services/auth_service.dart';
import 'package:http/http.dart' as http;

/// Único punto que arma headers y maneja el 401 (sesión vencida).
class ApiClient {
  ApiClient._();
  static final instance = ApiClient._();

  final http.Client _client = http.Client();

  Map<String, String> _headers({required bool auth}) {
    final session = SessionStore.current;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-App-Token': ApiConfig.appToken,
      if (auth && session != null) 'Authorization': session.authorizationHeader,
    };
  }

  Future<http.Response> post(
    String url, {
    Object? body,
    bool auth = false,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final res = await _client
        .post(
          Uri.parse(url),
          headers: _headers(auth: auth),
          body: body,
        )
        .timeout(timeout);
    await _handleUnauthorized(res, auth);
    return res;
  }

  Future<http.Response> get(
    String url, {
    bool auth = true,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final res = await _client
        .get(Uri.parse(url), headers: _headers(auth: auth))
        .timeout(timeout);
    await _handleUnauthorized(res, auth);
    return res;
  }

  Future<void> _handleUnauthorized(http.Response res, bool auth) async {
    if (auth && res.statusCode == 401) {
      await AuthService.logout(); // limpia sesión y manda a login
    }
  }
}
