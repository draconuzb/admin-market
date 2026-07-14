import '../../core/api/dio_client.dart';
import '../../models/order.dart';
import '../../models/page.dart';

class OrdersRepository {
  OrdersRepository(this._api);
  final ApiClient _api;

  Future<List<Order>> checkout({String? comment}) async {
    final resp = await _api.post('/orders/checkout', data: {'comment': comment});
    return (resp.data['orders'] as List)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Paged<Order>> list({String? status, int page = 1, int pageSize = 20}) async {
    final resp = await _api.get('/orders', query: {
      if (status != null) 'status': status,
      'page': page,
      'page_size': pageSize,
    });
    return Paged.fromJson(resp.data as Map<String, dynamic>, Order.fromJson);
  }

  Future<Order> detail(int id) async {
    final resp = await _api.get('/orders/$id');
    return Order.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Order> updateStatus(int id, String status) async {
    final resp = await _api.patch('/orders/$id/status', data: {'status': status});
    return Order.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> reorder(int id) => _api.post('/orders/$id/reorder');
}
