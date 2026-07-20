import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/download/download_service.dart';
import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../providers.dart';
import '../../../shared/widgets/async_views.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../orders/orders_providers.dart';

/// Factory view of an order with forward-only status actions.
class FactoryOrderDetailScreen extends ConsumerWidget {
  const FactoryOrderDetailScreen({super.key, required this.orderId});
  final int orderId;

  // (labelKey, targetStatus, isDanger) for the current status.
  static const _actions = {
    'new': [('factory.action_confirm', 'confirmed', false), ('factory.action_cancel', 'cancelled', true)],
    'confirmed': [('factory.action_ship', 'shipped', false), ('factory.action_cancel', 'cancelled', true)],
    'shipped': [('factory.action_deliver', 'delivered', false)],
  };

  Future<void> _act(BuildContext context, WidgetRef ref, String target) async {
    try {
      await ref.read(ordersRepositoryProvider).updateStatus(orderId, target);
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
      await ref.read(downloadServiceProvider).download(
            '/orders/$orderId/invoice',
            'hisob-faktura-$orderId.pdf',
            'application/pdf',
          );
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
      appBar: AppBar(
        title: Text('orders.order_no'.tr(args: ['$orderId'])),
        actions: [
          IconButton(
            tooltip: 'orders.download_invoice'.tr(),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => _downloadInvoice(context, ref),
          ),
        ],
      ),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(orderDetailProvider(orderId)),
        ),
        data: (o) {
          final actions = _actions[o.status] ?? const [];
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OrderStatusBadge(status: o.status),
                    ),
                    const SizedBox(height: 12),
                    if (o.hasShipping)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on, color: AppTheme.accent, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if ((o.shippingName ?? '').isNotEmpty)
                                      Text('${o.shippingName} · ${o.shippingPhone ?? ''}',
                                          style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text(o.shippingAddress ?? ''),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    for (final item in o.items)
                      Card(
                        child: ListTile(
                          title: Text(item.productName),
                          subtitle: Text('${item.quantity} × ${formatPrice(item.unitPrice)}'),
                          trailing: Text(formatPrice(item.subtotal),
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('orders.total'.tr(),
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(formatPrice(o.totalAmount),
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 17)),
                      ],
                    ),
                    if (o.comment != null && o.comment!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(o.comment!, style: TextStyle(color: Colors.grey.shade700)),
                    ],
                  ],
                ),
              ),
              if (actions.isNotEmpty)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        for (final (labelKey, target, danger) in actions) ...[
                          Expanded(
                            child: danger
                                ? OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      minimumSize: const Size.fromHeight(48),
                                    ),
                                    onPressed: () => _act(context, ref, target),
                                    child: Text(labelKey.tr()),
                                  )
                                : FilledButton(
                                    onPressed: () => _act(context, ref, target),
                                    child: Text(labelKey.tr()),
                                  ),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
