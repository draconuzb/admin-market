import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../providers.dart';
import '../../../shared/widgets/async_views.dart';
import '../admin_providers.dart';

class AdminRegistrationsScreen extends ConsumerWidget {
  const AdminRegistrationsScreen({super.key});

  Future<void> _act(BuildContext context, WidgetRef ref, int id, String action) async {
    try {
      await ref.read(adminRepositoryProvider).actOnRegistration(id, action);
      ref.invalidate(adminRegistrationsProvider);
      ref.invalidate(adminUsersProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminRegistrationsProvider);
    return Scaffold(
      appBar: AppBar(title: Text('admin.registrations_title'.tr())),
      body: async.when(
        loading: () => const ListSkeleton(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(adminRegistrationsProvider),
        ),
        data: (page) => page.items.isEmpty
            ? EmptyView(message: 'orders.empty'.tr())
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: page.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final r = page.items[i];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.fullName,
                                    style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text('${r.phone} · ${r.role} · ${r.companyName ?? 'admin.no_company'.tr()}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _act(context, ref, r.id, 'reject'),
                            child: Text('admin.reject'.tr(),
                                style: const TextStyle(color: Colors.red)),
                          ),
                          const SizedBox(width: 4),
                          FilledButton(
                            onPressed: () => _act(context, ref, r.id, 'approve'),
                            child: Text('admin.approve'.tr()),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
