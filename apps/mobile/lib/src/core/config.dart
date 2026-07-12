/// App-wide configuration.
///
/// The API base URL can be overridden at build/run time:
///   flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const String apiPrefix = '/api/v1';

  static String get apiUrl => '$apiBaseUrl$apiPrefix';

  /// Media (product images) are served from the API host under /media.
  static String mediaUrl(String path) {
    if (path.startsWith('http')) return path;
    return '$apiBaseUrl$path';
  }
}
