import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Datos de la sesión devuelta por el login.
class Session {
  Session({
    required this.name,
    required this.centerId,
    required this.centerName,
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresAt,
    this.permissions = const [],
    this.parameters = const {},
  });

  final String name;
  final String centerId;
  final String centerName;
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final DateTime expiresAt;
  final List<dynamic> permissions;
  final Map<String, dynamic> parameters;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Valor listo para el header Authorization de las siguientes peticiones.
  String get authorizationHeader => '$tokenType $accessToken';

  /// Construye la sesión a partir del campo "data" de la respuesta del login.
  factory Session.fromLoginData(Map<String, dynamic> data) {
    final user = (data['user'] as Map?)?.cast<String, dynamic>() ?? {};
    final auth = (data['auth'] as Map).cast<String, dynamic>();
    final expiresIn = (auth['expiresIn'] as num?)?.toInt() ?? 3600;

    return Session(
      name: user['name'] as String? ?? '',
      centerId: user['centerId'] as String? ?? '',
      centerName: user['centerName'] as String? ?? '',
      accessToken: auth['accessToken'] as String,
      refreshToken: auth['refreshToken'] as String? ?? '',
      tokenType: auth['tokenType'] as String? ?? 'Bearer',
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      permissions: (data['permissions'] as List?) ?? const [],
      parameters:
          (data['parameters'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'centerId': centerId,
    'centerName': centerName,
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'tokenType': tokenType,
    'expiresAt': expiresAt.toIso8601String(),
    'permissions': permissions,
    'parameters': parameters,
  };

  factory Session.fromJson(Map<String, dynamic> j) => Session(
    name: j['name'] as String? ?? '',
    centerId: j['centerId'] as String? ?? '',
    centerName: j['centerName'] as String? ?? '',
    accessToken: j['accessToken'] as String,
    refreshToken: j['refreshToken'] as String? ?? '',
    tokenType: j['tokenType'] as String? ?? 'Bearer',
    expiresAt: DateTime.parse(j['expiresAt'] as String),
    permissions: (j['permissions'] as List?) ?? const [],
    parameters: (j['parameters'] as Map?)?.cast<String, dynamic>() ?? const {},
  );
}

/// Guarda la sesión de forma cifrada (Keychain en iOS, Keystore en Android).

class SessionStore {
  static const _storage = FlutterSecureStorage();
  static const _key = 'session';
  //PARA USUARIOS DE PRUEBA, SE PUEDE USAR ESTE USUARIO MASTER PARA INICIAR SESIÓN SIN CREDENCIALES
  static const String masterUser = 'auditor.master';
  static String get currentUsername => current?.name ?? '';

  /// true solo si la sesión actual es la del usuario especial offline.
  static bool get isMaster =>
      currentUsername.trim().toLowerCase() == masterUser;

  /// Sesión local para auditor.master: no toca la API ni el almacenamiento seguro.
  static void startMasterSession() {
    current = Session(
      name: masterUser,
      centerId: '',
      centerName: 'Pruebas',
      accessToken: '',
      refreshToken: '',
      tokenType: 'Bearer',
      expiresAt: DateTime.now().add(const Duration(days: 365)),
    );
  }

  ///

  /// Sesión en memoria para usarla en cualquier pantalla.
  static Session? current;

  static Future<void> save(Session s) async {
    current = s;
    await _storage.write(key: _key, value: jsonEncode(s.toJson()));
  }

  static Future<Session?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      return Session.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Lee la sesión guardada y la deja en memoria solo si sigue vigente.
  static Future<Session?> restore() async {
    final s = await read();
    if (s == null) return null;
    if (s.isExpired) {
      await clear();
      return null;
    }
    current = s;
    return s;
  }

  static Future<void> clear() async {
    current = null;
    await _storage.delete(key: _key);
  }
}
