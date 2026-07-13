import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});
  final String status;

  static const _colors = {
    'new': AppTheme.accent,
    'confirmed': AppTheme.warning,
    'shipped': AppTheme.purple,
    'delivered': AppTheme.success,
    'cancelled': AppTheme.danger,
  };

  static const _icons = {
    'new': Icons.fiber_new_rounded,
    'confirmed': Icons.check_circle_outline,
    'shipped': Icons.local_shipping_outlined,
    'delivered': Icons.done_all_rounded,
    'cancelled': Icons.cancel_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status] ?? Colors.grey;
    final icon = _icons[status];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            'orders.status.$status'.tr(),
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
