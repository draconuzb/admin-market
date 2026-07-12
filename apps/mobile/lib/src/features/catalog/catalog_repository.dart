import '../../core/api/dio_client.dart';
import '../../models/catalog.dart';
import '../../models/page.dart';

class CatalogRepository {
  CatalogRepository(this._api);
  final ApiClient _api;

  Future<List<Category>> categories() async {
    final resp = await _api.get('/categories');
    return (resp.data as List).map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Paged<Product>> products({
    String? search,
    int? categoryId,
    int? factoryId,
    String sort = 'newest',
    int page = 1,
    int pageSize = 20,
  }) async {
    final resp = await _api.get('/products', query: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null) 'category_id': categoryId,
      if (factoryId != null) 'factory_id': factoryId,
      'sort': sort,
      'page': page,
      'page_size': pageSize,
    });
    return Paged.fromJson(resp.data as Map<String, dynamic>, Product.fromJson);
  }

  Future<Product> product(int id) async {
    final resp = await _api.get('/products/$id');
    return Product.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Paged<Factory>> factories({int page = 1, int pageSize = 20}) async {
    final resp = await _api.get('/factories', query: {'page': page, 'page_size': pageSize});
    return Paged.fromJson(resp.data as Map<String, dynamic>, Factory.fromJson);
  }
}
