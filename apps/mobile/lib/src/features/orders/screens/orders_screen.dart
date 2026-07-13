import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../shared/widgets/async_views.dart';
import '../../../shared/widgets/status_badge.dart';
import '../orders_providers.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(ordersListProvider);
    return Scaffold(
      backgroundColor: AppTheme.bg,
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
                  ListView(),
                  EmptyView(message: 'orders.empty'.tr(),
                      icon: Icons.receipt_long_outlined),
                ])
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  itemCount: orders.length,
                  itemBuilder: (_, i) {
                    final o = orders[i];
                    return GestureDetector(
                      onTap: () => context.push('/order/${o.id}'),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('orders.order_no'.tr(args: ['${o.id}']),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700, fontSize: 16)),
                                OrderStatusBadge(status: o.status),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('dd.MM.yyyy, HH:mm').format(o.createdAt),
                                  style: const TextStyle(
                                      fontSize: 13, color: AppTheme.textSecondary),
                                ),
                                Text(formatPrice(o.totalAmount),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700, fontSize: 16)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
