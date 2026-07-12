import '../core/format.dart';

class CartLine {
  CartLine({
    required this.id,
    required this.productId,
    required this.nameUz,
    required this.unitPrice,
    required this.quantity,
    required this.minOrderQty,
    required this.stockQty,
    required this.subtotal,
    required this.factoryId,
    required this.factoryName,
  });

  final int id;
  final int productId;
  final String nameUz;
  final num unitPrice;
  final int quantity;
  final int minOrderQty;
  final int stockQty;
  final num subtotal;
  final int factoryId;
  final String factoryName;

  factory CartLine.fromJson(Map<String, dynamic> j) => CartLine(
        id: j['id'] as int,
        productId: j['product_id'] as int,
        nameUz: j['name_uz'] as String,
        unitPrice: parseNum(j['unit_price']),
        quantity: j['quantity'] as int,
        minOrderQty: j['min_order_qty'] as int,
        stockQty: j['stock_qty'] as int,
        subtotal: parseNum(j['subtotal']),
        factoryId: j['factory_id'] as int,
        factoryName: j['factory_name'] as String,
      );
}

class Cart {
  Cart({required this.items, required this.total, required this.factoryCount});

  final List<CartLine> items;
  final num total;
  final int factoryCount;

  bool get isEmpty => items.isEmpty;
  int get count => items.length;

  factory Cart.fromJson(Map<String, dynamic> j) => Cart(
        items: (j['items'] as List).map((e) => CartLine.fromJson(e as Map<String, dynamic>)).toList(),
        total: parseNum(j['total']),
        factoryCount: j['factory_count'] as int,
      );

  static Cart empty() => Cart(items: const [], total: 0, factoryCount: 0);
}
