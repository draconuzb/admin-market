import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});
  final String status;

  static const _colors = {
    'new': Color(0xFF1E4FD8),        // blue
    'confirmed': Color(0xFFEA8600),  // orange
    'shipped': Color(0xFF7B3FE4),    // purple
    'delivered': Color(0xFF1E9E4A),  // green
    'cancelled': Color(0xFFD23B3B),  // red
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'orders.status.$status'.tr(),
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
