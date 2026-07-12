import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/format.dart';
import '../../../providers.dart';
import '../../../shared/widgets/async_views.dart';
import '../../../shared/widgets/status_badge.dart';
import '../orders_providers.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final int orderId;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(ordersRepositoryProvider).updateStatus(orderId, 'cancelled');
      ref.invalidate(orderDetailProvider(orderId));
      ref.invalidate(ordersListProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(orderDetailProvider(orderId));
    return Scaffold(
      appBar: AppBar(title: Text('orders.order_no'.tr(args: ['$orderId']))),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
        ),
        data: (o) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('orders.items'.tr(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                OrderStatusBadge(status: o.status),
              ],
            ),
            const SizedBox(height: 8),
            for (final item in o.items)
              Card(
                child: ListTile(
                  title: Text(item.productName),
                  subtitle: Text('${item.quantity} × ${formatPrice(item.unitPrice)}'),
                  trailing: Text(formatPrice(item.subtotal),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            const SizedBox(height: 12),
            _row('orders.total'.tr(), formatPrice(o.totalAmount), bold: true),
            _row('orders.commission'.tr(),
                '${formatPrice(o.commissionAmount)} (${o.commissionPercent}%)'),
            if (o.comment != null && o.comment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(o.comment!, style: TextStyle(color: Colors.grey.shade700)),
            ],
            if (o.canBuyerCancel) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => _cancel(context, ref),
                icon: const Icon(Icons.close),
                label: Text('orders.cancel_order'.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 15)),
            Text(value,
                style: TextStyle(
                    fontSize: bold ? 17 : 15,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
          ],
        ),
      );
}
