import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../shared/widgets/async_views.dart';
import '../../../shared/widgets/status_badge.dart';
import '../orders_providers.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ordersListProvider);
    return Scaffold(
      appBar: AppBar(title: Text('orders.title'.tr())),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(ordersListProvider),
        child: async.when(
          loading: () => const ListSkeleton(),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(ordersListProvider),
          ),
          data: (orders) => orders.isEmpty
              ? Stack(children: [
                  ListView(), // enables pull-to-refresh on empty
                  EmptyView(message: 'orders.empty'.tr(), icon: Icons.receipt_long_outlined),
                ])
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final o = orders[i];
                    return Card(
                      child: ListTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('orders.order_no'.tr(args: ['${o.id}']),
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                            OrderStatusBadge(status: o.status),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(DateFormat('dd.MM.yyyy HH:mm').format(o.createdAt),
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              const SizedBox(height: 4),
                              Text(formatPrice(o.totalAmount),
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        onTap: () => context.push('/order/${o.id}'),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
