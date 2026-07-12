import '../core/format.dart';

class OrderItem {
  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  final int id;
  final int productId;
  final String productName;
  final num unitPrice;
  final int quantity;
  final num subtotal;

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        id: j['id'] as int,
        productId: j['product_id'] as int,
        productName: j['product_name'] as String,
        unitPrice: parseNum(j['unit_price']),
        quantity: j['quantity'] as int,
        subtotal: parseNum(j['subtotal']),
      );
}

class Order {
  Order({
    required this.id,
    required this.factoryId,
    required this.status,
    required this.totalAmount,
    required this.commissionPercent,
    required this.commissionAmount,
    required this.comment,
    required this.createdAt,
    required this.items,
  });

  final int id;
  final int factoryId;
  final String status;
  final num totalAmount;
  final num commissionPercent;
  final num commissionAmount;
  final String? comment;
  final DateTime createdAt;
  final List<OrderItem> items;

  bool get canBuyerCancel => status == 'new';

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'] as int,
        factoryId: j['factory_id'] as int,
        status: j['status'] as String,
        totalAmount: parseNum(j['total_amount']),
        commissionPercent: parseNum(j['commission_percent']),
        commissionAmount: parseNum(j['commission_amount']),
        comment: j['comment'] as String?,
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
        items: (j['items'] as List).map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList(),
      );
}
