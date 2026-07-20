import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/download/download_service.dart';
import '../../../core/format.dart';
import '../../../core/pwa/pwa.dart';
import '../../../core/theme.dart';
import '../../../providers.dart';
import '../../../shared/widgets/async_views.dart';
import '../factory_providers.dart';

const _xlsxMime = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

class FactoryProductsScreen extends ConsumerWidget {
  const FactoryProductsScreen({super.key});

  Future<void> _export(BuildContext context, WidgetRef ref, String what) async {
    try {
      await ref.read(downloadServiceProvider).download(
            '/factory/$what/export',
            '$what.xlsx',
            _xlsxMime,
            query: {'format': 'xlsx'},
          );
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _downloadTemplate(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(downloadServiceProvider).download(
            '/factory/products/import-template',
            'shablon.xlsx',
            _xlsxMime,
            query: {'format': 'xlsx'},
          );
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final file = await pickFile('.csv,.xlsx');
    if (file == null) return;
    try {
      final res = await ref.read(factoryRepositoryProvider).importProducts(file.bytes, file.name);
      ref.invalidate(factoryProductsProvider);
      if (context.mounted) {
        final created = res['created'] ?? 0;
        final updated = res['updated'] ?? 0;
        final errors = (res['errors'] as List?) ?? const [];
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('factory.import_result'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('factory.import_created'.tr(args: ['$created'])),
                Text('factory.import_updated'.tr(args: ['$updated'])),
                if (errors.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('factory.import_errors'.tr(args: ['${errors.length}']),
                      style: const TextStyle(color: AppTheme.danger)),
                  for (final e in errors.take(5))
                    Text('• ${'factory.import_row'.tr()} ${e['row']}: ${e['message']}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text('common.ok'.tr())),
            ],
          ),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

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
      appBar: AppBar(
        title: Text('factory.products_title'.tr()),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              switch (v) {
                case 'export_products':
                  _export(context, ref, 'products');
                case 'export_orders':
                  _export(context, ref, 'orders');
                case 'import':
                  _import(context, ref);
                case 'template':
                  _downloadTemplate(context, ref);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'export_products',
                child: _menuRow(Icons.download_outlined, 'factory.export_products'.tr()),
              ),
              PopupMenuItem(
                value: 'export_orders',
                child: _menuRow(Icons.download_outlined, 'factory.export_orders'.tr()),
              ),
              PopupMenuItem(
                value: 'import',
                child: _menuRow(Icons.upload_file_outlined, 'factory.import_products'.tr()),
              ),
              PopupMenuItem(
                value: 'template',
                child: _menuRow(Icons.description_outlined, 'factory.import_template'.tr()),
              ),
            ],
          ),
        ],
      ),
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
                        title: Row(
                          children: [
                            Flexible(child: Text(p.name(lang), overflow: TextOverflow.ellipsis)),
                            if (p.isLowStock) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.warning.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('factory.low_stock'.tr(),
                                    style: const TextStyle(
                                        fontSize: 11, color: AppTheme.warning,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ],
                        ),
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

  Widget _menuRow(IconData icon, String label) => Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.accent),
          const SizedBox(width: 12),
          Text(label),
        ],
      );
}
