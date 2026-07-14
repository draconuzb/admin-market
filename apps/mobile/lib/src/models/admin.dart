import '../core/format.dart';

class Registration {
  Registration({
    required this.id,
    required this.phone,
    required this.role,
    required this.fullName,
    required this.status,
    required this.companyName,
  });

  final int id;
  final String phone;
  final String role;
  final String fullName;
  final String status;
  final String? companyName;

  factory Registration.fromJson(Map<String, dynamic> j) => Registration(
        id: j['id'] as int,
        phone: j['phone'] as String,
        role: j['role'] as String,
        fullName: j['full_name'] as String,
        status: j['status'] as String,
        companyName: j['company_name'] as String?,
      );
}

class AdminUserRow {
  AdminUserRow({
    required this.id,
    required this.phone,
    required this.role,
    required this.fullName,
    required this.status,
  });

  final int id;
  final String phone;
  final String role;
  final String fullName;
  final String status;

  factory AdminUserRow.fromJson(Map<String, dynamic> j) => AdminUserRow(
        id: j['id'] as int,
        phone: j['phone'] as String,
        role: j['role'] as String,
        fullName: j['full_name'] as String,
        status: j['status'] as String,
      );
}

class AdminProduct {
  AdminProduct({
    required this.id,
    required this.factoryId,
    required this.nameUz,
    required this.price,
    required this.stockQty,
    required this.isActive,
  });

  final int id;
  final int factoryId;
  final String nameUz;
  final num price;
  final int stockQty;
  final bool isActive;

  factory AdminProduct.fromJson(Map<String, dynamic> j) => AdminProduct(
        id: j['id'] as int,
        factoryId: j['factory_id'] as int,
        nameUz: j['name_uz'] as String,
        price: parseNum(j['price']),
        stockQty: j['stock_qty'] as int,
        isActive: j['is_active'] as bool,
      );
}

class ReportSummary {
  ReportSummary({required this.ordersCount, required this.gmv, required this.commissionTotal});
  final int ordersCount;
  final num gmv;
  final num commissionTotal;

  factory ReportSummary.fromJson(Map<String, dynamic> j) => ReportSummary(
        ordersCount: j['orders_count'] as int,
        gmv: parseNum(j['gmv']),
        commissionTotal: parseNum(j['commission_total']),
      );
}

class DailyPoint {
  DailyPoint({required this.date, required this.orders, required this.revenue});
  final String date;
  final int orders;
  final num revenue;

  factory DailyPoint.fromJson(Map<String, dynamic> j) => DailyPoint(
        date: j['date'] as String,
        orders: j['orders'] as int,
        revenue: parseNum(j['revenue']),
      );
}

class TopProduct {
  TopProduct({required this.name, required this.quantity, required this.revenue});
  final String name;
  final int quantity;
  final num revenue;

  factory TopProduct.fromJson(Map<String, dynamic> j) => TopProduct(
        name: j['name'] as String,
        quantity: j['quantity'] as int,
        revenue: parseNum(j['revenue']),
      );
}

class FactoryAnalytics {
  FactoryAnalytics({required this.daily, required this.topProducts, required this.statusCounts});
  final List<DailyPoint> daily;
  final List<TopProduct> topProducts;
  final Map<String, int> statusCounts;

  factory FactoryAnalytics.fromJson(Map<String, dynamic> j) => FactoryAnalytics(
        daily: (j['daily'] as List).map((e) => DailyPoint.fromJson(e as Map<String, dynamic>)).toList(),
        topProducts:
            (j['top_products'] as List).map((e) => TopProduct.fromJson(e as Map<String, dynamic>)).toList(),
        statusCounts: (j['status_counts'] as Map).map((k, v) => MapEntry(k.toString(), v as int)),
      );
}

class FactoryStats {
  FactoryStats({
    required this.ordersTotal,
    required this.ordersThisMonth,
    required this.revenueThisMonth,
    required this.commissionThisMonth,
    required this.pendingOrders,
  });

  final int ordersTotal;
  final int ordersThisMonth;
  final num revenueThisMonth;
  final num commissionThisMonth;
  final int pendingOrders;

  factory FactoryStats.fromJson(Map<String, dynamic> j) => FactoryStats(
        ordersTotal: j['orders_total'] as int,
        ordersThisMonth: j['orders_this_month'] as int,
        revenueThisMonth: parseNum(j['revenue_this_month']),
        commissionThisMonth: parseNum(j['commission_this_month']),
        pendingOrders: j['pending_orders'] as int,
      );
}
