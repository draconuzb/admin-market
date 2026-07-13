import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper over SharedPreferences for tokens and preferences.
/// Works across web + mobile.
class TokenStorage {
  TokenStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _langKey = 'language';
  static const _themeKey = 'theme_mode'; // 'light' | 'dark' | 'system'

  String? get access => _prefs.getString(_accessKey);
  String? get refresh => _prefs.getString(_refreshKey);
  String? get language => _prefs.getString(_langKey);
  String? get themeMode => _prefs.getString(_themeKey);

  Future<void> saveTokens(String access, String refresh) async {
    await _prefs.setString(_accessKey, access);
    await _prefs.setString(_refreshKey, refresh);
  }

  Future<void> saveLanguage(String code) => _prefs.setString(_langKey, code);

  Future<void> saveThemeMode(String mode) => _prefs.setString(_themeKey, mode);

  Future<void> clear() async {
    await _prefs.remove(_accessKey);
    await _prefs.remove(_refreshKey);
  }

  bool get hasSession => access != null;
}
