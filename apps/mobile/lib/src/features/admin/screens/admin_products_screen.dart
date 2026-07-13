import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/format.dart';
import '../../../providers.dart';
import '../../../shared/widgets/async_views.dart';
import '../admin_providers.dart';

class AdminProductsScreen extends ConsumerWidget {
  const AdminProductsScreen({super.key});

  Future<void> _act(BuildContext context, WidgetRef ref, int id, String action) async {
    try {
      await ref.read(adminRepositoryProvider).moderateProduct(id, action);
      ref.invalidate(adminProductsProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminProductsProvider);
    return Scaffold(
      appBar: AppBar(title: Text('admin.products_title'.tr())),
      body: async.when(
        loading: () => const ListSkeleton(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(adminProductsProvider),
        ),
        data: (page) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: page.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final p = page.items[i];
            return Card(
              child: ListTile(
                leading: Icon(
                  p.isActive ? Icons.visibility : Icons.visibility_off,
                  color: p.isActive ? Colors.green : Colors.grey,
                ),
                title: Text(p.nameUz),
                subtitle: Text(
                    '${formatPrice(p.price)} · ${'factory.field_stock'.tr()}: ${p.stockQty}'),
                trailing: TextButton(
                  onPressed: () => _act(context, ref, p.id, p.isActive ? 'hide' : 'unhide'),
                  child: Text(p.isActive ? 'admin.hide'.tr() : 'admin.unhide'.tr(),
                      style: TextStyle(color: p.isActive ? Colors.red : Colors.green)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
