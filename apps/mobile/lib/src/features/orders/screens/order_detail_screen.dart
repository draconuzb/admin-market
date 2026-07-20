import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/download/download_service.dart';
import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../models/order.dart';
import '../../../providers.dart';
import '../../../shared/widgets/async_views.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../cart/cart_controller.dart';
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

  Future<void> _downloadInvoice(BuildContext context, WidgetRef ref) async {
    try {
      final ok = await ref.read(downloadServiceProvider).download(
            '/orders/$orderId/invoice',
            'hisob-faktura-$orderId.pdf',
            'application/pdf',
          );
      if (context.mounted && !ok) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('common.error_generic'.tr())));
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _reorder(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(ordersRepositoryProvider).reorder(orderId);
      await ref.read(cartControllerProvider.notifier).reload();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('orders.reordered'.tr())));
        context.go('/cart');
      }
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

            // Delivery address (snapshot)
            if (o.hasShipping) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: AppTheme.accent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('address.delivery'.tr(),
                              style: const TextStyle(
                                  fontSize: 13, color: AppTheme.textSecondary)),
                          const SizedBox(height: 4),
                          if ((o.shippingName ?? '').isNotEmpty)
                            Text('${o.shippingName} · ${o.shippingPhone ?? ''}',
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600)),
                          Text(o.shippingAddress ?? '',
                              style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

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
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Text(o.comment!,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 14)),
              ),
            ],

            // Status timeline
            if (o.events.isNotEmpty) ...[
              const SizedBox(height: 16),
              _Timeline(events: o.events),
            ],

            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _downloadInvoice(context, ref),
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
              label: Text('orders.download_invoice'.tr()),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _reorder(context, ref),
              icon: const Icon(Icons.refresh, size: 20),
              label: Text('orders.reorder'.tr()),
            ),
            if (o.canBuyerCancel) ...[
              const SizedBox(height: 12),
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

/// Vertical status history for an order.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.events});
  final List<OrderEvent> events;

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

  String _fmt(DateTime dt) {
    final d = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}  ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('orders.timeline'.tr(),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          for (int i = 0; i < events.length; i++)
            _step(events[i], isLast: i == events.length - 1),
        ],
      ),
    );
  }

  Widget _step(OrderEvent e, {required bool isLast}) {
    final color = _colors[e.status] ?? AppTheme.textSecondary;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icons[e.status] ?? Icons.circle, size: 15, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: AppTheme.separator),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 8 : 16, top: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('orders.status.${e.status}'.tr(),
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600, color: color)),
                  const SizedBox(height: 2),
                  Text(_fmt(e.createdAt),
                      style: const TextStyle(
                          fontSize: 12.5, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
