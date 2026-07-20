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

class OrderEvent {
  OrderEvent({required this.status, this.actorRole, required this.createdAt});

  final String status;
  final String? actorRole;
  final DateTime createdAt;

  factory OrderEvent.fromJson(Map<String, dynamic> j) => OrderEvent(
        status: j['status'] as String,
        actorRole: j['actor_role'] as String?,
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
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
    this.shippingName,
    this.shippingPhone,
    this.shippingAddress,
    this.events = const [],
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
  final String? shippingName;
  final String? shippingPhone;
  final String? shippingAddress;
  final List<OrderEvent> events;

  bool get canBuyerCancel => status == 'new';
  bool get hasShipping => (shippingAddress ?? '').isNotEmpty;

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
        shippingName: j['shipping_name'] as String?,
        shippingPhone: j['shipping_phone'] as String?,
        shippingAddress: j['shipping_address'] as String?,
        events: (j['events'] as List?)
                ?.map((e) => OrderEvent.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
