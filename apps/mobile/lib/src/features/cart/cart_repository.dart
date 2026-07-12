import '../../core/api/dio_client.dart';
import '../../models/cart.dart';

class CartRepository {
  CartRepository(this._api);
  final ApiClient _api;

  Future<Cart> get() async {
    final resp = await _api.get('/cart');
    return Cart.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Cart> addItem(int productId, int quantity) async {
    final resp = await _api.post('/cart/items',
        data: {'product_id': productId, 'quantity': quantity});
    return Cart.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Cart> updateItem(int itemId, int quantity) async {
    final resp = await _api.patch('/cart/items/$itemId', data: {'quantity': quantity});
    return Cart.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Cart> removeItem(int itemId) async {
    final resp = await _api.delete('/cart/items/$itemId');
    return Cart.fromJson(resp.data as Map<String, dynamic>);
  }
}
