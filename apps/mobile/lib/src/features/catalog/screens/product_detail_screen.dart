import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/format.dart';
import '../../../models/catalog.dart';
import '../../../shared/widgets/async_views.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/qty_stepper.dart';
import '../../cart/cart_controller.dart';
import '../catalog_providers.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final int productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(productDetailProvider(productId));
    return Scaffold(
      appBar: AppBar(),
      body: async.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(productDetailProvider(productId)),
        ),
        data: (p) => _Detail(product: p),
      ),
    );
  }
}

class _Detail extends ConsumerStatefulWidget {
  const _Detail({required this.product});
  final Product product;
  @override
  ConsumerState<_Detail> createState() => _DetailState();
}

class _DetailState extends ConsumerState<_Detail> {
  late int _qty = widget.product.minOrderQty;
  bool _adding = false;

  Future<void> _addToCart() async {
    setState(() => _adding = true);
    try {
      await ref.read(cartControllerProvider.notifier).add(widget.product.id, _qty);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('product.added'.tr())),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final lang = context.locale.languageCode;
    final canOrder = p.inStock;
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              AspectRatio(
                aspectRatio: 1.4,
                child: ProductImageBox(
                  imageUrl: p.images.isNotEmpty ? p.images.first : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name(lang),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(formatPrice(p.price),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.primary,
                        )),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _chip(context, Icons.shopping_bag_outlined,
                            '${'product.min_order'.tr()}: ${p.minOrderQty}'),
                        const SizedBox(width: 8),
                        _chip(
                          context,
                          Icons.inventory_2_outlined,
                          canOrder
                              ? 'product.in_stock'.tr(args: ['${p.stockQty}'])
                              : 'product.out_of_stock'.tr(),
                          danger: !canOrder,
                        ),
                      ],
                    ),
                    if (p.factory != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Text(p.factory!.name.characters.first)),
                          title: Text(p.factory!.name),
                          subtitle: p.factory!.region != null ? Text(p.factory!.region!) : null,
                        ),
                      ),
                    ],
                    if ((p.description(lang) ?? '').isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(p.description(lang)!,
                          style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (canOrder)
                  QtyStepper(
                    value: _qty,
                    min: p.minOrderQty,
                    max: p.stockQty,
                    onChanged: (v) => setState(() => _qty = v),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: (!canOrder || _adding) ? null : _addToCart,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: Text(canOrder
                        ? 'product.add_to_cart'.tr()
                        : 'product.out_of_stock'.tr()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(BuildContext context, IconData icon, String text, {bool danger = false}) {
    final color = danger ? Colors.red : Colors.grey.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (danger ? Colors.red : Colors.grey).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}
