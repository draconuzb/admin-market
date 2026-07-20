import '../../core/api/dio_client.dart';
import '../../models/address.dart';

class AddressesRepository {
  AddressesRepository(this._api);
  final ApiClient _api;

  Future<List<Address>> list() async {
    final resp = await _api.get('/addresses');
    return (resp.data as List)
        .map((e) => Address.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Address> create(Map<String, dynamic> data) async {
    final resp = await _api.post('/addresses', data: data);
    return Address.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Address> update(int id, Map<String, dynamic> data) async {
    final resp = await _api.patch('/addresses/$id', data: data);
    return Address.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> setDefault(int id) => _api.post('/addresses/$id/default');

  Future<void> delete(int id) => _api.delete('/addresses/$id');
}
