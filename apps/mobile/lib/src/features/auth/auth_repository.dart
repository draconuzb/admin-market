import '../../core/api/dio_client.dart';
import '../../models/user.dart';

class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  /// Returns (user, devOtp). devOtp is only present in dev (console SMS).
  Future<(AppUser, String?)> register({
    required String phone,
    required String password,
    required String role,
    required String fullName,
    required String companyName,
    required String language,
  }) async {
    final resp = await _api.post('/auth/register', data: {
      'phone': phone,
      'password': password,
      'role': role,
      'full_name': fullName,
      'language': language,
      'company': {'name': companyName},
    });
    final user = AppUser.fromJson(resp.data['user'] as Map<String, dynamic>);
    return (user, resp.data['dev_otp'] as String?);
  }

  Future<void> verifyOtp(String phone, String code, {String purpose = 'register'}) async {
    await _api.post('/auth/verify-otp',
        data: {'phone': phone, 'code': code, 'purpose': purpose});
  }

  /// Returns the token pair (access, refresh).
  Future<(String, String)> login(String phone, String password) async {
    final resp = await _api.post('/auth/login', data: {'phone': phone, 'password': password});
    return (resp.data['access'] as String, resp.data['refresh'] as String);
  }

  Future<AppUser> me() async {
    final resp = await _api.get('/auth/me');
    return AppUser.fromJson(resp.data as Map<String, dynamic>);
  }
}
