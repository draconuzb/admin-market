import '../../core/api/dio_client.dart';

class Company {
  Company({required this.name, this.type, this.address, this.region, this.inn, this.logoUrl});
  final String name;
  final String? type;
  final String? address;
  final String? region;
  final String? inn;
  final String? logoUrl;

  factory Company.fromJson(Map<String, dynamic> j) => Company(
        name: j['name'] as String,
        type: j['type'] as String?,
        address: j['address'] as String?,
        region: j['region'] as String?,
        inn: j['inn'] as String?,
        logoUrl: j['logo_url'] as String?,
      );
}

class Profile {
  Profile({
    required this.id,
    required this.phone,
    required this.role,
    required this.fullName,
    required this.language,
    required this.status,
    this.company,
  });

  final int id;
  final String phone;
  final String role;
  final String fullName;
  final String language;
  final String status;
  final Company? company;

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'] as int,
        phone: j['phone'] as String,
        role: j['role'] as String,
        fullName: j['full_name'] as String,
        language: j['language'] as String? ?? 'uz',
        status: j['status'] as String,
        company: j['company'] != null
            ? Company.fromJson(j['company'] as Map<String, dynamic>)
            : null,
      );
}

class ProfileRepository {
  ProfileRepository(this._api);
  final ApiClient _api;

  Future<Profile> get() async {
    final resp = await _api.get('/profile');
    return Profile.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Profile> update(Map<String, dynamic> data) async {
    final resp = await _api.patch('/profile', data: data);
    return Profile.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> changePassword(String oldPassword, String newPassword) {
    return _api.post('/profile/change-password',
        data: {'old_password': oldPassword, 'new_password': newPassword});
  }
}
