import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audit_tool/auth/session.dart';
import 'package:audit_tool/core/api_config.dart';
import 'package:audit_tool/core/network/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/routes/app_routes.dart';

class AuthResult {
  const AuthResult.ok(this.session) : ok = true, error = null;
  const AuthResult.fail(this.error) : ok = false, session = null;

  final bool ok;
  final String? error;
  final Session? session;
}

class AuthService {
  Map<String, dynamic> _body(String user, String password) => {
    'username': user,
    'password': password,
  };

  Future<AuthResult> signIn(String user, String password) async {
    if (!ApiConfig.isConfigured) {
      return const AuthResult.fail(
        'Configura la URL del API (ícono de engrane) antes de iniciar sesión.',
      );
    }
    if (ApiConfig.appToken.isEmpty) {
      return const AuthResult.fail(
        'Falta configurar el token de la app (APP_TOKEN).',
      );
    }

    try {
      final response = await ApiClient.instance.post(
        ApiConfig.loginUrl,
        body: jsonEncode(_body(user, password)),
      );

      Map<String, dynamic>? json;
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) json = decoded;
      } on FormatException {
        json = null;
      }

      final data = json?['data'];
      if (response.statusCode == 200 &&
          json?['success'] == true &&
          data is Map<String, dynamic>) {
        final session = Session.fromLoginData(data);
        await SessionStore.save(session);
        return AuthResult.ok(session);
      }

      return AuthResult.fail(
        (json?['message'] as String?) ??
            'No se pudo iniciar sesión (código ${response.statusCode}).',
      );
    } on TimeoutException {
      return const AuthResult.fail(
        'El servidor tardó demasiado en responder. Intenta de nuevo.',
      );
    } on HandshakeException {
      return const AuthResult.fail(
        'No se pudo establecer una conexión segura con el servidor.',
      );
    } on SocketException {
      return const AuthResult.fail(
        'Sin conexión con el servidor. Revisa tu internet.',
      );
    } on http.ClientException {
      return const AuthResult.fail(
        'No se pudo conectar con el servidor. Intenta de nuevo.',
      );
    } catch (e) {
      debugPrint('signIn error: $e');
      return const AuthResult.fail(
        'Ocurrió un error inesperado al iniciar sesión.',
      );
    }
  }

  Future<Map<String, dynamic>?> getProfile() async {
    if (SessionStore.current == null) return null;
    try {
      final response = await ApiClient.instance.get(ApiConfig.meUrl);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic> && decoded['success'] == true) {
          return decoded['data'] as Map<String, dynamic>?;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Cierra sesión: borra SOLO la sesión (SecureStorage).
  /// La URL del API (SharedPreferences) se conserva.
  /// Es estático para poder llamarlo desde pantallas y desde el cliente HTTP.
  static bool _loggingOut = false;

  static Future<void> logout({bool notifyServer = false}) async {
    if (_loggingOut) return; // evita doble logout si llegan varios 401
    _loggingOut = true;
    try {
      if (notifyServer && SessionStore.current != null) {
        try {
          // Best-effort: si el endpoint no existe o falla, igual cerramos local.
          await http
              .post(
                Uri.parse(ApiConfig.logoutUrl),
                headers: {
                  'Accept': 'application/json',
                  'X-App-Token': ApiConfig.appToken,
                  'Authorization': SessionStore.current!.authorizationHeader,
                },
              )
              .timeout(const Duration(seconds: 5));
        } catch (_) {}
      }
      await SessionStore.clear();
      AppRouter.resetToLogin();
    } finally {
      _loggingOut = false;
    }
  }
}
