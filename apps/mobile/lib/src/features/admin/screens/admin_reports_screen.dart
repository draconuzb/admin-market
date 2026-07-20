import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/download/download_service.dart';
import '../../../core/format.dart';
import '../../../shared/widgets/async_views.dart';
import '../admin_providers.dart';

const _xlsxMime = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  Future<void> _exportOrders(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(downloadServiceProvider).download(
            '/admin/orders/export',
            'barcha-buyurtmalar.xlsx',
            _xlsxMime,
            query: {'format': 'xlsx'},
          );
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminReportProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('admin.reports_title'.tr()),
        actions: [
          IconButton(
            tooltip: 'admin.export_orders'.tr(),
            icon: const Icon(Icons.download_outlined),
            onPressed: () => _exportOrders(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminReportProvider),
        child: async.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(adminReportProvider),
          ),
          data: (r) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _tile(context, 'admin.orders_count'.tr(), '${r.ordersCount}', Icons.receipt_long),
              _tile(context, 'admin.gmv'.tr(), formatPrice(r.gmv), Icons.trending_up),
              _tile(context, 'admin.commission_total'.tr(), formatPrice(r.commissionTotal), Icons.percent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, String label, String value, IconData icon) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      );
}
