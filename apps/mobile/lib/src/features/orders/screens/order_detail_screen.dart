import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/format.dart';
import '../../../core/theme.dart';
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
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: Text('orders.order_no'.tr(args: ['$orderId']))),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
        ),
        data: (o) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Status',
                      style: TextStyle(fontSize: 15, color: AppTheme.textSecondary)),
                  OrderStatusBadge(status: o.status),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Items
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Text('orders.items'.tr(),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                  for (int i = 0; i < o.items.length; i++) ...[
                    if (i > 0)
                      const Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Divider(height: 0.5, thickness: 0.5),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(o.items[i].productName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500, fontSize: 15)),
                                const SizedBox(height: 2),
                                Text(
                                  '${o.items[i].quantity} × ${formatPrice(o.items[i].unitPrice)}',
                                  style: const TextStyle(
                                      fontSize: 13, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Text(formatPrice(o.items[i].subtotal),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  _row('orders.total'.tr(), formatPrice(o.totalAmount), bold: true),
                  const Divider(height: 16),
                  _row('orders.commission'.tr(),
                      '${formatPrice(o.commissionAmount)} (${o.commissionPercent}%)'),
                ],
              ),
            ),

            if (o.comment != null && o.comment!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Text(o.comment!,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 14)),
              ),
            ],

            if (o.canBuyerCancel) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.danger,
                ),
                onPressed: () => _cancel(context, ref),
                icon: const Icon(Icons.close, size: 20),
                label: Text('orders.cancel_order'.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 15, color: AppTheme.textSecondary)),
            Text(value,
                style: TextStyle(
                    fontSize: bold ? 18 : 15,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
          ],
        ),
      );
}
