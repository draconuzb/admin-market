import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/format.dart';
import '../../../core/theme.dart';
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
      backgroundColor: AppTheme.surface,
      appBar: AppBar(backgroundColor: AppTheme.surface),
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
  int _imgIdx = 0;

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
    final hasImages = p.images.isNotEmpty;
    final multiImage = p.images.length > 1;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // ── Image carousel ──
              Container(
                height: 320,
                color: AppTheme.fill,
                child: multiImage
                    ? Stack(
                        children: [
                          PageView.builder(
                            itemCount: p.images.length,
                            onPageChanged: (i) => setState(() => _imgIdx = i),
                            itemBuilder: (_, i) => ProductImageBox(
                              imageUrl: p.images[i],
                              productName: p.name(lang),
                            ),
                          ),
                          Positioned(
                            bottom: 16, left: 0, right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(p.images.length, (i) {
                                final active = i == _imgIdx;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: active ? 20 : 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: active ? AppTheme.accent : Colors.black26,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      )
                    : ProductImageBox(
                        imageUrl: hasImages ? p.images.first : null,
                        productName: p.name(lang),
                      ),
              ),

              // ── Product info ──
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name(lang),
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w700, height: 1.2)),
                    const SizedBox(height: 10),
                    Text(
                      formatPrice(p.price),
                      style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w800,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tags
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _infoChip(Icons.shopping_bag_outlined,
                            '${'product.min_order'.tr()}: ${p.minOrderQty}'),
                        _infoChip(
                          canOrder ? Icons.check_circle_outline : Icons.cancel_outlined,
                          canOrder
                              ? 'product.in_stock'.tr(args: ['${p.stockQty}'])
                              : 'product.out_of_stock'.tr(),
                          danger: !canOrder,
                        ),
                      ],
                    ),

                    // Factory
                    if (p.factory != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.fill,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [AppTheme.accent, AppTheme.accentLight]),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                p.factory!.name.characters.first.toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(p.factory!.name,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  if (p.factory!.region != null)
                                    Text(p.factory!.region!,
                                        style: const TextStyle(
                                            fontSize: 13, color: AppTheme.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Description
                    if ((p.description(lang) ?? '').isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('product.description'.tr(),
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(p.description(lang)!,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, height: 1.5, fontSize: 15)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Bottom bar ──
        Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20,
              MediaQuery.of(context).padding.bottom + 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border(top: BorderSide(color: AppTheme.separator, width: 0.5)),
          ),
          child: Row(
            children: [
              if (canOrder) ...[
                QtyStepper(
                  value: _qty,
                  min: p.minOrderQty,
                  max: p.stockQty,
                  onChanged: (v) => setState(() => _qty = v),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: (!canOrder || _adding) ? null : _addToCart,
                  child: _adding
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(canOrder
                          ? 'product.add_to_cart'.tr()
                          : 'product.out_of_stock'.tr()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String text, {bool danger = false}) {
    final color = danger ? AppTheme.danger : AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.fill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
