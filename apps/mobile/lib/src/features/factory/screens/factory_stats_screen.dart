import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format.dart';
import '../../../shared/widgets/async_views.dart';
import '../factory_providers.dart';

class FactoryStatsScreen extends ConsumerWidget {
  const FactoryStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(factoryStatsProvider);
    return Scaffold(
      appBar: AppBar(title: Text('factory.stats_title'.tr())),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(factoryStatsProvider),
        child: async.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(factoryStatsProvider),
          ),
          data: (s) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _tile(context, 'factory.orders_total'.tr(), '${s.ordersTotal}', Icons.receipt_long),
              _tile(context, 'factory.orders_month'.tr(), '${s.ordersThisMonth}', Icons.calendar_month),
              _tile(context, 'factory.pending'.tr(), '${s.pendingOrders}', Icons.hourglass_top),
              _tile(context, 'factory.revenue_month'.tr(), formatPrice(s.revenueThisMonth), Icons.payments),
              _tile(context, 'factory.commission_month'.tr(), formatPrice(s.commissionThisMonth), Icons.percent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
