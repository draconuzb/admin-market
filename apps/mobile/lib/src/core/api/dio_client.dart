import 'package:dio/dio.dart';

import '../config.dart';
import '../storage.dart';
import 'api_exception.dart';

/// Configured Dio client: injects the bearer token, and on 401 transparently
/// refreshes the token once and retries the failed request.
class ApiClient {
  ApiClient(this._storage, {this.onSessionExpired}) {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        contentType: 'application/json',
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _storage.access;
          if (token != null && options.headers['Authorization'] == null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: _onError,
      ),
    );
  }

  late final Dio dio;
  final TokenStorage _storage;
  final void Function()? onSessionExpired;
  bool _refreshing = false;

  Future<void> _onError(DioException e, ErrorInterceptorHandler handler) async {
    final isAuthCall = e.requestOptions.path.startsWith('/auth/');
    if (e.response?.statusCode == 401 && !isAuthCall && _storage.refresh != null) {
      try {
        final newAccess = await _refreshToken();
        if (newAccess != null) {
          final opts = e.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newAccess';
          final clone = await dio.fetch(opts);
          return handler.resolve(clone);
        }
      } catch (_) {
        // fall through to session-expired handling
      }
      onSessionExpired?.call();
    }
    handler.next(e);
  }

  Future<String?> _refreshToken() async {
    if (_refreshing) return null;
    _refreshing = true;
    try {
      final resp = await dio.post(
        '/auth/refresh',
        data: {'refresh_token': _storage.refresh},
        options: Options(headers: {'Authorization': null}),
      );
      final access = resp.data['access'] as String;
      final refresh = resp.data['refresh'] as String;
      await _storage.saveTokens(access, refresh);
      return access;
    } finally {
      _refreshing = false;
    }
  }

  // Convenience wrappers that surface ApiException.
  Future<Response> get(String path, {Map<String, dynamic>? query}) =>
      _guard(() => dio.get(path, queryParameters: query));

  Future<Response> post(String path, {Object? data}) =>
      _guard(() => dio.post(path, data: data));

  Future<Response> patch(String path, {Object? data}) =>
      _guard(() => dio.patch(path, data: data));

  Future<Response> delete(String path) => _guard(() => dio.delete(path));

  Future<Response> _guard(Future<Response> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
