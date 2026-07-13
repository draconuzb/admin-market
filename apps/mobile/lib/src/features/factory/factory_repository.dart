import '../../core/api/dio_client.dart';
import '../../models/admin.dart';
import '../../models/catalog.dart';

class FactoryRepository {
  FactoryRepository(this._api);
  final ApiClient _api;

  Future<List<Product>> products() async {
    final resp = await _api.get('/factory/products');
    return (resp.data as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Product> create(Map<String, dynamic> data) async {
    final resp = await _api.post('/factory/products', data: data);
    return Product.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Product> update(int id, Map<String, dynamic> data) async {
    final resp = await _api.patch('/factory/products/$id', data: data);
    return Product.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _api.delete('/factory/products/$id');

  Future<FactoryStats> stats() async {
    final resp = await _api.get('/factory/stats');
    return FactoryStats.fromJson(resp.data as Map<String, dynamic>);
  }
}
