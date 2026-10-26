import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'session.dart';

/// Resultado de un intento de inicio de sesión.
class AuthResult {
  const AuthResult.ok(this.session) : ok = true, error = null;
  const AuthResult.fail(this.error) : ok = false, session = null;

  final bool ok;
  final String? error;
  final Session? session;
}

class AuthService {
  AuthService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Cuerpo de la petición de login.
  /// OJO: confirma con quien te compartió el API los nombres exactos de los
  /// campos (y si pide datos del dispositivo, como un device id).
  Map<String, dynamic> _body(String user, String password) => {
    'username': user,
    'password': password,
  };

  Future<AuthResult> signIn(String user, String password) async {
    if (ApiConfig.appToken.isEmpty) {
      return const AuthResult.fail(
        'Falta configurar el token de la app (APP_TOKEN).',
      );
    }

    try {
      final response = await _client
          .post(
            Uri.parse(ApiConfig.loginUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-App-Token': ApiConfig.appToken,
            },
            body: jsonEncode(_body(user, password)),
          )
          .timeout(const Duration(seconds: 20));

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

      // Error del servidor (por ejemplo 401: credenciales inválidas).
      final message = json?['message'] as String?;
      return AuthResult.fail(
        message ?? 'No se pudo iniciar sesión (código ${response.statusCode}).',
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
    } catch (_) {
      return const AuthResult.fail(
        'Ocurrió un error inesperado al iniciar sesión.',
      );
    }
  }
}
