/// App-wide configuration.
///
/// The API base URL is overridden at build/run time. Local dev passes an
/// explicit host; production builds pass an empty value (same-origin):
///   flutter run   -d chrome --dart-define=API_BASE_URL=http://localhost:8000
///   flutter build web --release --dart-define=API_BASE_URL=
///
/// The default is EMPTY (same-origin) on purpose: a plain `flutter build web`
/// must never bake in localhost and break the deployed site.
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String apiPrefix = '/api/v1';

  static String get apiUrl => '$apiBaseUrl$apiPrefix';

  /// Media (product images) are served from the API host under /media.
  static String mediaUrl(String path) {
    if (path.startsWith('http')) return path;
    return '$apiBaseUrl$path';
  }
}
