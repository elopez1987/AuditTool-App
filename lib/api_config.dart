/* class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://audittool.test',
  );

  /// Se envía en el header X-App-Token en cada petición.
  static const appToken = String.fromEnvironment(
    '5623e76c241327da147fce96144d82ea4e6c79cca7ea244043f647f8f7e870db',
  );

  static String get loginUrl => '$baseUrl/api/v1/auth/login';
}
 */
//Nueva integración de la API

import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const _baseUrlKey = 'api_base_url';

  static const _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://audittool.test',
  );

  static const appToken = String.fromEnvironment(
    'API_APP_TOKEN',
    defaultValue: '',
  );

  static String _baseUrl = _defaultBaseUrl;

  static String get baseUrl => _baseUrl;

  static String get loginUrl => '$baseUrl/api/v1/auth/login';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_baseUrlKey) ?? _defaultBaseUrl;
  }

  static Future<void> saveBaseUrl(String value) async {
    final normalized = value.trim().replaceFirst(RegExp(r'/+$'), '');

    final uri = Uri.tryParse(normalized);

    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw ArgumentError('Ingresa una URL HTTP o HTTPS válida.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, normalized);
    _baseUrl = normalized;
  }
}
