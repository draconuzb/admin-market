import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/format.dart';
import '../../../providers.dart';
import '../../../shared/widgets/async_views.dart';
import '../factory_providers.dart';

class FactoryProductsScreen extends ConsumerWidget {
  const FactoryProductsScreen({super.key});

  Future<void> _delete(BuildContext context, WidgetRef ref, int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: Text('factory.delete_confirm'.tr()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('common.cancel'.tr())),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text('common.confirm'.tr())),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(factoryRepositoryProvider).delete(id);
      ref.invalidate(factoryProductsProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = context.locale.languageCode;
    final async = ref.watch(factoryProductsProvider);
    return Scaffold(
      appBar: AppBar(title: Text('factory.products_title'.tr())),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/factory/product/new'),
        icon: const Icon(Icons.add),
        label: Text('factory.add_product'.tr()),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(factoryProductsProvider),
        child: async.when(
          loading: () => const ListSkeleton(),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(factoryProductsProvider),
          ),
          data: (products) => products.isEmpty
              ? Stack(children: [ListView(), EmptyView(message: 'catalog.empty'.tr())])
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final p = products[i];
                    return Card(
                      child: ListTile(
                        title: Text(p.name(lang)),
                        subtitle: Text(
                          '${formatPrice(p.price)} · ${'factory.field_stock'.tr()}: ${p.stockQty}'
                          '${p.isActive ? '' : ' · ${'factory.hidden'.tr()}'}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => context.push('/factory/product/${p.id}/edit'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _delete(context, ref, p.id),
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
