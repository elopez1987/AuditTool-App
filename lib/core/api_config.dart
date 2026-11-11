import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const _baseUrlKey = '';
  static const _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const appToken = String.fromEnvironment(
    'X-App-Token',
    defaultValue:
        '5623e76c241327da147fce96144d82ea4e6c79cca7ea244043f647f8f7e870db',
  );

  static bool get isConfigured => _baseUrl.isNotEmpty;

  static String _baseUrl = _defaultBaseUrl;
  static String get baseUrl => _baseUrl;
  static String get loginUrl => _baseUrl + '/v1/auth/login';
  static String get meUrl => _baseUrl + '/v1/auth/me';
  static String get logoutUrl => _baseUrl + '/v1/auth/logout';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final savedUrl = prefs.getString(_baseUrlKey);

    _baseUrl = (savedUrl == null || savedUrl.isEmpty)
        ? _defaultBaseUrl
        : savedUrl;

    print('API CONFIG INICIALIZADA: $_baseUrl');
  }

  static Future<void> saveBaseUrl(String value) async {
    print('API Base URL: $baseUrl');
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
