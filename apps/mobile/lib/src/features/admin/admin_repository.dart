import '../../core/api/dio_client.dart';
import '../../models/admin.dart';
import '../../models/page.dart';

class AdminRepository {
  AdminRepository(this._api);
  final ApiClient _api;

  Future<Paged<Registration>> registrations({int page = 1}) async {
    final resp = await _api.get('/admin/registrations', query: {'page': page});
    return Paged.fromJson(resp.data as Map<String, dynamic>, Registration.fromJson);
  }

  Future<void> actOnRegistration(int id, String action) =>
      _api.patch('/admin/registrations/$id', data: {'action': action});

  Future<Paged<AdminUserRow>> users({int page = 1}) async {
    final resp = await _api.get('/admin/users', query: {'page': page});
    return Paged.fromJson(resp.data as Map<String, dynamic>, AdminUserRow.fromJson);
  }

  Future<void> actOnUser(int id, String action) =>
      _api.patch('/admin/users/$id', data: {'action': action});

  Future<Paged<AdminProduct>> products({int page = 1}) async {
    final resp = await _api.get('/admin/products', query: {'page': page});
    return Paged.fromJson(resp.data as Map<String, dynamic>, AdminProduct.fromJson);
  }

  Future<void> moderateProduct(int id, String action) =>
      _api.patch('/admin/products/$id', data: {'action': action});

  Future<Map<String, String>> getSettings() async {
    final resp = await _api.get('/admin/settings');
    return (resp.data['settings'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()));
  }

  Future<Map<String, String>> updateSettings(Map<String, String> settings) async {
    final resp = await _api.put('/admin/settings', data: {'settings': settings});
    return (resp.data['settings'] as Map).map((k, v) => MapEntry(k.toString(), v.toString()));
  }

  Future<ReportSummary> reportSummary() async {
    final resp = await _api.get('/admin/reports/summary');
    return ReportSummary.fromJson(resp.data as Map<String, dynamic>);
  }
}
