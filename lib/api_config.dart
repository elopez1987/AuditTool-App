class ApiConfig {
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
